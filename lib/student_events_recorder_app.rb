require 'pg'
require 'yaml'
require 'erb'
require 'base64'

class StudentEventsRecorderApp

  def initialize
    db_name, password, user = get_db_connection_info_from_rails
    @conn = PG::Connection.open(dbname: db_name, password: password, user: user)
  end

  def get_db_connection_info_from_rails
    root_dir = File.expand_path('../', File.dirname(__FILE__))
    db_config = YAML.load(ERB.new(File.read(root_dir + '/config/database.yml')).result)
    env = db_config[Rails.env]
    return env['database'], env['password'], env['username']
  end

  def call(env)
    raw_response = nil
    @req = Rack::Request.new(env)
    @resp = Rack::Response.new

    @http_basic = @req.env["HTTP_AUTHORIZATION"]
    if @req.path.end_with?('.html')
      @resp['Content-Type'] = 'text/html; charset=utf-8'
      @respdata = ''
      @request_type = :html
    else
      @resp['Content-Type'] = 'application/json; charset=utf-8'
      @respdata = {}
      @request_type = :json
    end

    serve_request

    raw_response = @resp.finish do
      if @req.path.end_with?('.json')
        @resp.write(MultiJson.encode(@respdata))
      else
        @resp.write(@respdata)
      end
    end
    raw_response
  end


  private
  def serve_request
    begin
      if @req.post? && @req.path == '/student_events/.json'
        serve_post_task
      elsif @req.get? && @req.path == '/student_events/status.json'
        serve_status
        #elsif @plugin_manager.serve_request(@req, @resp, @respdata)
        # ok
      else
        @resp.status = 404
        case @request_type
        when :json
          @respdata[:status] = 'not_found'
        when :html
          @respdata << "<html><body>Not found</body></html>"
        end
      end
    rescue BadRequest
      @resp.status = 500
      case @request_type
      when :json
        @respdata[:status] = 'bad_request'
      when :html
        @respdata << "<html><body>Bad request</body></html>"
      end
    rescue
      puts("Error processing request:\n#{$!}")
      @resp.status = 500
      case @request_type
      when :json
        @respdata[:status] = 'error'
      when :html
        @respdata << "<html><body>Error</body></html>"
      end
    end
  end

  def serve_status
    @respdata[:loadavg] = File.read("/proc/loadavg").split(' ')[0..2] if File.exist?("/proc/loadavg")
  end

  def serve_post_task
    if @req.params['events']
      handle_events
      @respdata[:status] = 'ok'
    else
      @resp.status = 500
      @respdata[:status] = 'busy'
    end
  end

  def handle_events
    user_id = get_user_id(@req.env["HTTP_AUTHORIZATION"])

    params = @req.params
    event_records = params['events'].values
    File.open(params['data'][:tempfile].path, 'rb') do |data_file|
      event_records.each do |record|
        puts record.inspect
        course_id = get_course_id(record['course_name'])
        exercise_name = get_exercise_name_within_course(course_id, record['exercise_name'])

        event_type = record['event_type']
        metadata = record['metadata']
        happened_at = record['happened_at']
        system_nano_time = record['system_nano_time']

        data_file.pos = record['data_offset'].to_i
        data = data_file.read(record['data_length'].to_i)

        #unless StudentEvent.supported_event_types.include?(event_type)
        #  raise "Invalid event type: '#{event_type}'"
        #end

        #check_json_syntax(metadata) if metadata

        event = {
          :user_id => user_id,
          :course_id => course_id,
          :exercise_name => exercise_name,
          :event_type => event_type,
          :metadata_json => metadata,
          :data => data,
          :happened_at => happened_at,
          :system_nano_time => system_nano_time
        }
        save_event(event)
      end
    end
  end

  def get_exercise_name_within_course(course_id, ex_name)
    result = @conn.exec("SELECT exercises.name FROM exercises WHERE exercises.course_id = $1 AND exercises.name = $2 LIMIT 1", [course_id, ex_name]).first
    if result
      result['name']
    else
      puts "cant find exercise"
      raise InvalidSqlReguest
    end
  end

  def get_course_id(course_name)
    result = @conn.exec('SELECT courses.id FROM courses WHERE courses.name = $1 LIMIT 1', [course_name]).first
    if result
       result['id']
    else
      puts "cant find course"
      raise InvalidSqlReguest
    end
  end

  def get_user_id(http_basic_auth)
    return nil if http_basic_auth.nil?

    username, password =  Base64.decode64(http_basic_auth.split(" ")[1]).split(":")
    user = User.authenticate(username, password)
    if user
      user.id
    else
      raise InvalidUser
    end
  end

  def fix_data(data)
    @conn.escape_bytea(data)
  end

  def save_event(event)
    puts "saving_event"
    result = @conn.exec('INSERT INTO student_events (course_id, data, event_type, exercise_name, happened_at, metadata_json, system_nano_time, user_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id',   [ event[:course_id], fix_data(event[:data]), event[:event_type], event[:exercise_name], event[:happened_at], event[:metadata_json], event[:system_nano_time], event[:user_id]])
    puts "saved #{result}"
    puts
  end
end

class BadRequest < StandardError; end
class InvalidSqlReguest < StandardError; end
class InvalidUser < StandardError; end
