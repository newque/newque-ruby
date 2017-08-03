class Pubsub_client

  @@ctx = ZMQ::Context.new

  attr_reader :sock, :thread

  def initialize host, port, options={}, poll_interval:50
    @addr = "tcp://#{host}:#{port}"
    @options = compute_options Zmq_tools::BASE_OPTIONS, options
    @poll_interval = poll_interval
  end

  # The socket connection happens here so that no network traffic occurs while not subscribed
  def subscribe
    raise newque_error ["Already subscribed, unsubscribe first"] if is_looping?

    @unsubscribe = false

    @sock = @@ctx.socket ZMQ::SUB
    Zmq_tools.set_zmq_sock_options @sock, @options

    @poller = ZMQ::Poller.new
    @poller.register_readable @sock

    @sock.connect @addr
    @sock.setsockopt(ZMQ::SUBSCRIBE, '')

    @thread = Thread.new do
      loop do
        buffers = []

        break if @unsubscribe

        while @poller.poll(@poll_interval) > 0
          @sock.recv_strings buffers, ZMQ::DONTWAIT
          yield parse_input buffers
        end

      end
      @sock.disconnect @addr
    end
    @thread
  end

  def unsubscribe
    @unsubscribe = true
    @thread.join if is_looping?
    nil
  end

  private

  def is_looping?
    !@thread.nil? && @thread.alive?
  end

  def parse_input buffers
    buf, *messages = buffers
    input = Input.decode buf

    payload = if !input.write_input.nil?
      Write_request.new input.write_input.atomic, input.write_input.ids
    elsif !input.read_input.nil?
      Read_request.new input.read_input.mode, input.read_input.limit
    elsif !input.count_input.nil?
      Count_request.new
    elsif !input.delete_input.nil?
      Delete_request.new
    elsif !input.health_input.nil?
      Health_request.new input.health_input.global
    else
      raise newque_error ["Cannot find a valid message type"]
    end

    Input_request.new input.channel, payload, messages
  end

end
