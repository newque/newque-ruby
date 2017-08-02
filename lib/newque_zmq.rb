class Newque_zmq

  BASE_OPTIONS = {
    ZMQ_MAXMSGSIZE: -1,
    ZMQ_LINGER: 60000,
    ZMQ_RECONNECT_IVL: 100,
    ZMQ_RECONNECT_IVL_MAX: 60000,
    ZMQ_BACKLOG: 100,
    ZMQ_SNDHWM: 5000,
    ZMQ_RCVHWM: 5000
  }
  # BASE_OPTIONS, with the values being the ZMQ constants for those options
  ZMQ_OPT_MAPPING = Hash[
      BASE_OPTIONS.map do |name, value|
      [name, ZMQ.const_get(name.to_s.slice(4..-1))]
    end
  ]

  @@ctx = ZMQ::Context.new

  attr_reader :sock

  def initialize host, port, options, timeout
    @timeout = timeout

    @sock = @@ctx.socket ZMQ::DEALER
    set_zmq_sock_options options

    @poller = ZMQ::Poller.new
    @poller.register_readable @sock

    @sock.connect "tcp://#{host}:#{port}"
  end

  def write channel, atomic, msgs, ids=nil
    input = Input.new(channel: channel, write_input: Write_Input.new(atomic: atomic, ids: ids))
    buffers = send_request input, msgs
    output = parse_response buffers[1], :write_output
    Write_response.new output.saved
  end

  def read channel, mode, limit=nil
    buffers = send_request Input.new(channel: channel, read_input: Read_Input.new(mode: mode, limit: limit))
    output = parse_response buffers[1], :read_output
    Read_response.new output.length, output.last_id, output.last_timens, buffers.slice(2, buffers.size)
  end

  def count channel
    buffers = send_request Input.new(channel: channel, count_input: Count_Input.new)
    output = parse_response buffers[1], :count_output
    Count_response.new output.count
  end

  def delete channel
    buffers = send_request Input.new(channel: channel, delete_input: Delete_Input.new)
    output = parse_response buffers[1], :delete_output
    Delete_response.new
  end

  def health channel, global=false
    buffers = send_request Input.new(channel: channel, health_input: Health_Input.new(global: global))
    output = parse_response buffers[1], :health_output
    Health_response.new
  end

  private

  def set_zmq_sock_options options
    BASE_OPTIONS.each do |name, default_value|
      @sock.setsockopt ZMQ_OPT_MAPPING[name], (options[name] || default_value)
    end
  end

  def send_request input, msgs=[]
    id = SecureRandom.uuid
    meta = input.encode.to_s
    @sock.send_strings (msgs.size > 0 ? [id, meta] + msgs : [id, meta])
    get_response id
  end

  def get_response id
    loop_until = time_ms + @timeout
    time_left = @timeout

    loop do
      buffers = []

      if @poller.poll(time_left) == 0
        raise zmq_error "Timeout, no response received within #{@timeout} ms. Caution: The request might have been received and processed by the server regarless."
      end

      @sock.recv_strings buffers, ZMQ::DONTWAIT
      return buffers if buffers[0] == id
      time_left = [(loop_until - time_ms), 0].max
    end
  end

  def parse_response buffer, type
    output = Output.decode buffer
    if output.errors
      raise newque_error output.errors
    end
    output.send type
  end

  def time_ms
    (Time.now.to_f * 1000).to_i
  end

end
