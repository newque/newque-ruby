class Client
  extend Forwardable

  def_delegators :@instance, :write, :read, :read_stream, :count, :delete, :health

  attr_reader :protocol

  def initialize protocol, host, port, protocol_options:nil, timeout:10000
    @protocol = protocol
    @instance = if protocol == :zmq
      Newque_zmq.new host, port, (protocol_options || {}), timeout
    elsif protocol == :http
      Newque_http.new host, port, (protocol_options || {}), timeout
    else
      raise NewqueError.new "Invalid protocol [#{protocol}]. Must be either :zmq or :http"
    end
  end

end
