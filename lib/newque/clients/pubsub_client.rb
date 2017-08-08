require 'ffi-rzmq'
require 'securerandom'

module Newque

  class Pubsub_client

    def initialize host, port, protocol_options:{}, socket_wait:100
      @ctx = ZMQ::Context.new
      @addr = "tcp://#{host}:#{port}"
      @options = Util.compute_options Zmq_tools::BASE_OPTIONS, protocol_options
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
          break if @disconnect
          next if @poller.poll(@socket_wait) == 0
          buffers = []
          @sock.recv_strings buffers, ZMQ::DONTWAIT
          parsed = Zmq_tools.parse_input buffers
          @listeners.values.each do |listener|
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
        @sock.close
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

    def print_uncaught_exception err, block_name
      puts "Uncaught exception in Pubsub_client.#{block_name} block: #{err.to_s} #{JSON.pretty_generate(err.backtrace)}"
    end

  end

end
