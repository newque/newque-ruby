require 'ffi-rzmq'
require 'securerandom'

module Newque

  class Newque_zmq
    attr_reader :sock

    def initialize host, port, options, timeout
      @ctx = ZMQ::Context.new
      @options = Util.compute_options Zmq_tools::BASE_OPTIONS, options
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
      send_request input, msgs do |buffers|
        output = parse_response buffers[0], :write_output
        Write_response.new output.saved
      end
    end

    def read channel, mode, limit=nil
      input = Input.new(channel: channel, read_input: Read_Input.new(mode: mode, limit: limit))
      send_request input do |buf, *messages|
        output = parse_response buf, :read_output
        Read_response.new output.length, output.last_id, output.last_timens, messages
      end
    end

    def read_stream channel, mode, limit=nil
      raise NewqueError.new "Read_stream is only available in :http mode"
    end

    def count channel
      input = Input.new(channel: channel, count_input: Count_Input.new)
      send_request input do |buffers|
        output = parse_response buffers[0], :count_output
        Count_response.new output.count
      end
    end

    def delete channel
      input = Input.new(channel: channel, delete_input: Delete_Input.new)
      send_request input do |buffers|
        output = parse_response buffers[0], :delete_output
        Delete_response.new
      end
    end

    def health channel, global=false
      input = Input.new(channel: channel, health_input: Health_Input.new(global: global))
      send_request input do |buffers|
        output = parse_response buffers[0], :health_output
        Health_response.new
      end
    end

    private

    def send_request input, msgs=[], async:false, &block
      id = SecureRandom.uuid
      meta = input.encode.to_s
      thread = register id, &block
      @sock.send_strings (msgs.size > 0 ? [id, meta] + msgs : [id, meta]), ZMQ::DONTWAIT
      thread
    end

    def start_loop
      @thread = Thread.new do
        while @poller.poll(:blocking) > 0
          buffers = []
          @sock.recv_strings buffers, ZMQ::DONTWAIT
          id, *frames = buffers

          thread = @router[id]
          while thread.status == 'run'
            # If the scheduler didn't run the other thread and execute its Thread.stop
            # then we have to wait before we can continue. Sleep 0 yields to the scheduler.
            sleep 0
          end

          thread.thread_variable_set :result, frames
          thread.run
        end
      end
    end

    def register id
      thread = Thread.new do
        Thread.stop
        @router.delete id
        yield Thread.current.thread_variable_get(:result)
      end
      Thread.pass # Give a hint to schedule the new thread now
      @router[id] = thread
    end

    def parse_response buffer, type
      output = Output.decode buffer
      if output.errors
        raise newque_error output.errors
      end
      output.send type
    end

  end

end
