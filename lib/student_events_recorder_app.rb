require 'pg'
require 'yaml'
require 'erb'


class StudentEventsRecorderApp

  def initialize
    db_name, password = get_db_connection_info_from_rails
    @conn = PG.connect(dbname: db_name, password: password)
  end

  def get_db_connection_info_from_rails
    root_dir = File.expand_path('../', File.dirname(__FILE__))
    db_config = YAML.load(ERB.new(File.read(root_dir + '/config/database.yml')).result)
    env = db_config[Rails.env]
    return env['database'], env['password']
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
      puts @req.path
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
    puts params['data'].inspect
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

  def get_exercise_name_within_course(course, ex_name)
    @conn.exec("SELECT exercises.name FROM exercises WHERE exercises.course_id = $1 AND exercises.name = $2 LIMIT 1", [1, 'viikko3-3.1.Polynomi']).first['name']
  end

  def get_course_id(course_name)
    @conn.exec('SELECT courses.id FROM courses WHERE courses.name = $1 LIMIT 1', [course_name]).first['id']
  end

  # TODO: implement real functionality!!!
  def get_user_id(http_basic_auth)
    return 2
  end
  # TODO: implement
  def save_event(event)
    puts "saving_event"
    puts event.inspect
    puts
    puts
  end
end

class BadRequest < StandardError; end

