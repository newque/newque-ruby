class Newque_http
  extend Forwardable

  BASE_OPTIONS = {
    https: false,
    http_format: :json,
    separator: "\n"
  }

  def_delegators :@instance, :write, :read
  attr_reader :conn, :options

  def initialize host, port, options, timeout
    @host = host
    @port = port
    @options = compute_options BASE_OPTIONS, options
    @timeout = timeout / 1000.0

    @conn = Faraday.new({ url: "#{@options[:https] ? "https" : "http"}://#{host}:#{port}" })

    @instance = if @options[:http_format] == :json
      Http_json.new self
    elsif @options[:http_format] == :plaintext
      Http_plaintext.new self
    end
  end

  def read_stream channel, mode, limit=nil
    Enumerator.new do |generator|
      Net::HTTP.start(@host, @port) do |http|
        req = Net::HTTP::Get.new "/v1/#{channel}"
        req['newque-mode'] = mode
        req['newque-read-max'] = limit unless limit.nil?
        req['Transfer-Encoding'] = 'chunked'
        http.open_timeout = @timeout
        http.read_timeout = @timeout

        http.request req do |res|
          if res.code != '200'
            generator << parse_json_response(res.body) # Will throw
          else
            leftover = nil
            res.read_body do |chunk|
              lines = "#{leftover || ''}#{chunk}".split(@options[:separator], -1)
              *fulls, partial = lines
              fulls.each do |msg|
                generator << msg
              end
              leftover = partial
            end
            generator << leftover unless leftover.nil?
          end
        end
      end
    end
  end

  def count channel
    res = @conn.get do |req|
      set_req_options req
      req.url "/v1/#{channel}/count"
    end
    parsed = parse_json_response res.body
    Count_response.new parsed['count']
  end

  def delete channel
    res = @conn.delete do |req|
      set_req_options req
      req.url "/v1/#{channel}"
    end
    parsed = parse_json_response res.body
    Delete_response.new
  end

  def health channel, global=false
    res = @conn.get do |req|
      set_req_options req
      req.url "/v1#{global ? '' : '/' + channel}/health"
    end
    parsed = parse_json_response res.body
    Health_response.new
  end

  private

  def set_req_options req
    req.options.open_timeout = @timeout
    req.options.timeout = @timeout
  end

  def parse_json_response body
    parsed = JSON.parse body
    if parsed['errors'].size > 0
      raise newque_error parsed['errors']
    end
    parsed
  end

end
