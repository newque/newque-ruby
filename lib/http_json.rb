class Http_json
  def initialize http
    @http = http
  end

  def write channel, atomic, msgs, ids=nil
    Thread.new do
      body = {
        'atomic' => false,
        'messages' => msgs
      }
      body["ids"] = ids unless ids.nil?
      res = @http.conn.post do |req|
        @http.send :set_req_options, req
        req.url "/v1/#{channel}"
        req.body = body.to_json
      end
      parsed = @http.send :parse_json_response, res.body
      Write_response.new parsed['saved']
    end
  end

  def read channel, mode, limit=nil
    Thread.new do
      res = @http.conn.get do |req|
        @http.send :set_req_options, req
        req.url "/v1/#{channel}"
        req.headers['newque-mode'] = mode
        req.headers['newque-read-max'] = limit unless limit.nil?
      end
      parsed = @http.send :parse_json_response, res.body
      Read_response.new(
        res.headers['newque-response-length'].to_i,
        res.headers['newque-response-last-id'],
        res.headers['newque-response-last-ts'].to_i,
        parsed['messages']
      )
    end
  end

end
