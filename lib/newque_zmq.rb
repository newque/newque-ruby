class Newque_zmq
  attr_reader :sock

  def initialize host, port, options, timeout
    @ctx = ZMQ::Context.new
    @options = compute_options Zmq_tools::BASE_OPTIONS, options
    @timeout = timeout

    @sock = @ctx.socket ZMQ::DEALER
    Zmq_tools.set_zmq_sock_options @sock, @options

    @poller = ZMQ::Poller.new
    @poller.register_readable @sock

    @router = {}
    @sock.connect "tcp://#{host}:#{port}"
    start_loop
  end

  def write channel, atomic, msgs, ids=nil
    input = Input.new(channel: channel, write_input: Write_Input.new(atomic: atomic, ids: ids))
    id = send_request input, msgs

    register id do |buffers|
      output = parse_response buffers[0], :write_output
      Write_response.new output.saved
    end
  end

  def read channel, mode, limit=nil
    id = send_request Input.new(channel: channel, read_input: Read_Input.new(mode: mode, limit: limit))
    register id do |buf, *messages|
      output = parse_response buf, :read_output
      Read_response.new output.length, output.last_id, output.last_timens, messages
    end
  end

  def count channel
    id = send_request Input.new(channel: channel, count_input: Count_Input.new)
    register id do |buffers|
      output = parse_response buffers[0], :count_output
      Count_response.new output.count
    end
  end

  def delete channel
    id = send_request Input.new(channel: channel, delete_input: Delete_Input.new)
    register id do |buffers|
      output = parse_response buffers[0], :delete_output
      Delete_response.new
    end
  end

  def health channel, global=false
    id = send_request Input.new(channel: channel, health_input: Health_Input.new(global: global))
    register id do |buffers|
      output = parse_response buffers[0], :health_output
      Health_response.new
    end
  end

  private

  def send_request input, msgs=[], async:false
    id = SecureRandom.uuid
    meta = input.encode.to_s
    @sock.send_strings (msgs.size > 0 ? [id, meta] + msgs : [id, meta])
    id
  end

  def start_loop
    @thread = Thread.new do
      while @poller.poll(:blocking) > 0
        buffers = []
        @sock.recv_strings buffers, ZMQ::DONTWAIT
        id, *frames = buffers
        @router[id].thread_variable_set :result, frames
        @router[id].wakeup
      end
    end
  end

  def register id, &block
    @router[id] = Thread.new do
      Thread.stop
      @router.delete id
      block.call(Thread.current.thread_variable_get :result)
    end
  end

  def parse_response buffer, type
    output = Output.decode buffer
    if output.errors
      raise newque_error output.errors
    end
    output.send type
  end

end
