class Http_plaintext
  def initialize http
    @http = http
  end

  def write channel, atomic, msgs, ids=nil
    head, *tail = msgs
    raise newque_error ["No messages given"] if head.nil?

    stream = StringIO.new
    stream.write head
    if msgs.size > 1
      tail.each do |msg|
        stream.write @http.options[:separator]
        stream.write msg
      end
    end

    Thread.new do
      res = @http.conn.post do |req|
        @http.send :set_req_options, req
        req.url "/v1/#{channel}"
        req.body = stream.string

        req.headers['newque-mode'] = if atomic then 'atomic'
          elsif msgs.size == 1 then 'single'
          else 'multiple'
        end
        req.headers['newque-msg-id'] = ids unless ids.nil?
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
      if res.status == 200
        Read_response.new(
          res.headers['newque-response-length'].to_i,
          res.headers['newque-response-last-id'],
          res.headers['newque-response-last-ts'].to_i,
          res.body.split(@http.options[:separator])
        )
      else
        @http.send :parse_json_response, res.body
      end
    end
  end

end
