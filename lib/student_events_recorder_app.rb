class StudentEventsRecorderApp

  def call(env)
    raw_response = nil
    @req = Rack::Request.new(env)
    @resp = Rack::Response.new
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
      if @req.post? && @req.path == '/student_events.json'
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
      AppLog.warn("Error processing request:\n#{AppLog.fmt_exception($!)}")
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
      # it shoud do somethig with events json :D
      @respdata[:status] = 'ok'
    else
      @resp.status = 500
      @respdata[:status] = 'busy'
    end
  end
end
