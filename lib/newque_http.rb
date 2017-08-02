class Newque_http

  BASE_OPTIONS = {
    https: false
  }

  def initialize host, port, options, timeout
    https = options[:https].nil? ? BASE_OPTIONS[:https] : options[:https]
    @conn = Faraday.new({ url: "#{https ? "https" : "http"}://#{host}:#{port}" })

  end

  def write channel, atomic, msgs, ids=nil
    body = {
      'atomic' => false,
      'messages' => msgs
    }
    body["ids"] = ids unless ids.nil?
    res = @conn.post do |req|
      req.url "/v1/#{channel}"
      req.body = body.to_json
    end
    parsed = parse_json_response res.body
    Write_response.new parsed['saved']
  end

  def read channel, mode, limit=nil
    res = @conn.get do |req|
      req.url "/v1/#{channel}"
      req.headers['newque-mode'] = mode
      req.headers['newque-read-max'] = limit unless limit.nil?
    end
    parsed = parse_json_response res.body
    Read_response.new(
      res.headers['newque-response-length'].to_i,
      res.headers['newque-response-last-id'],
      res.headers['newque-response-last-ts'].to_i,
      parsed['messages']
    )
  end

  def count channel
    res = @conn.get do |req|
      req.url "/v1/#{channel}/count"
    end
    parsed = parse_json_response res.body
    Count_response.new parsed['count']
  end

  def delete channel
    res = @conn.delete do |req|
      req.url "/v1/#{channel}"
    end
    parsed = parse_json_response res.body
    Delete_response.new
  end

  def health channel, global=false
    res = @conn.get do |req|
      req.url "/v1#{global ? '' : '/' + channel}/health"
    end
    parsed = parse_json_response res.body
    Health_response.new
  end

  private

  def parse_json_response body
    parsed = JSON.parse body
    if parsed['errors'].size > 0
      raise newque_error parsed['errors']
    end
    parsed
  end

end
