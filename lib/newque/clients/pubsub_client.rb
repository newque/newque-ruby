require 'ffi-rzmq'
require 'securerandom'

module Newque

  class Pubsub_client
    attr_reader :sock, :thread

    def initialize host, port, options={}, socket_wait:100
      @ctx = ZMQ::Context.new
      @addr = "tcp://#{host}:#{port}"
      @options = Util.compute_options Zmq_tools::BASE_OPTIONS, options
      @socket_wait = socket_wait
      @disconnect = false
      @ready

      @listeners = {}
      @error_handlers = []
    end

    def add_error_handler &block
      @error_handlers << block
    end

    def subscribe &block
      @disconnect = false
      id = SecureRandom.uuid
      @listeners[id] = block
      start_loop unless is_looping?
      Thread.new do
        @ready.join(1)
        id
      end
    end

    # The socket connection happens here so that no network traffic occurs while not subscribed
    def start_loop
      @disconnect = false
      @sock = @ctx.socket ZMQ::SUB
      Zmq_tools.set_zmq_sock_options @sock, @options

      @poller = ZMQ::Poller.new
      @poller.register_readable @sock

      @sock.connect @addr
      @sock.setsockopt(ZMQ::SUBSCRIBE, '')

      @ready = Util.wait_t
      @thread = Thread.new do
        @poller.poll(@socket_wait)
        Util.resolve_t @ready, ''
        loop do
          next if @poller.poll(@socket_wait) == 0
          break if @disconnect
          buffers = []
          @sock.recv_strings buffers, ZMQ::DONTWAIT
          @listeners.values.each do |listener|
            parsed = parse_input buffers
            begin
              listener.(parsed)
            rescue => listener_error
              print_uncaught_exception(listener_error, 'subscribe') if @error_handlers.size == 0
              @error_handlers.each do |err_handler|
                begin
                  err_handler.(listener_error)
                rescue => uncaught_err
                  print_uncaught_exception uncaught_err, 'add_error_handler'
                end
              end
            end
          end
        end
        @sock.disconnect @addr
      end
      @ready
    end

    def unsubscribe id
      @listeners.delete id
      nil
    end

    def disconnect
      @disconnect = true
      nil
    end

    private

    def is_looping?
      !@thread.nil? && @thread.alive?
    end

    def parse_input buffers
      buf, *messages = buffers
      input = Input.decode buf

      action = if !input.write_input.nil?
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
        raise NewqueError.new "Cannot find a valid message type"
      end

      Input_request.new input.channel, action, messages
    end

    def print_uncaught_exception err, block_name
      puts "Uncaught exception in Pubsub_client.#{block_name} block: #{err.to_s} #{JSON.pretty_generate(err.backtrace)}"
    end

  end

end
