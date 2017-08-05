require 'ffi-rzmq'

module Newque

  class Pubsub_client
    attr_reader :sock, :thread

    def initialize host, port, options={}, disconnection_delay:100
      @ctx = ZMQ::Context.new
      @addr = "tcp://#{host}:#{port}"
      @options = Util.compute_options Zmq_tools::BASE_OPTIONS, options
      @disconnection_delay = disconnection_delay

      @listeners = {}
    end

    def subscribe name, &block
      raise "A listener with the name #{name} already exists" if @listeners.has_key? name
      @listeners[name] = block
      start_loop unless is_looping?
      nil
    end

    # The socket connection happens here so that no network traffic occurs while not subscribed
    def start_loop
      @sock = @ctx.socket ZMQ::SUB
      Zmq_tools.set_zmq_sock_options @sock, @options

      @poller = ZMQ::Poller.new
      @poller.register_readable @sock

      @sock.connect @addr
      @sock.setsockopt(ZMQ::SUBSCRIBE, '')

      @thread = Thread.new do
        loop do
          break if @listeners.empty?

          while @poller.poll(@disconnection_delay) > 0 && !@listeners.empty?
            buffers = []
            @sock.recv_strings buffers, ZMQ::DONTWAIT
            @listeners.values.each do |listener|
              parsed = parse_input buffers
              listener.call parsed
            end
          end

        end
        @sock.disconnect @addr
      end
    end

    def unsubscribe name
      @listeners.delete name
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
        raise newque_error ["Cannot find a valid message type"]
      end

      Input_request.new input.channel, action, messages
    end

  end

end
