require 'ffi-rzmq'

module Newque

  class Fifo_client

    STATES = [:NEW, :CONNECTING, :RUNNING, :DISCONNECTING, :CLOSING, :CLOSED]

    def initialize host, port, protocol_options:{}, socket_wait:100
      @ctx = ZMQ::Context.new
      @addr = "tcp://#{host}:#{port}"
      @options = Util.compute_options Zmq_tools::BASE_OPTIONS, protocol_options
      @socket_wait = socket_wait
      @state = 0
    end

    def connect &block
      raise NewqueError.new "Cannot connect because this client is #{current_state}" unless current_state == :NEW
      next_state :CONNECTING
      @handler = block
      @sock = @ctx.socket ZMQ::DEALER
      Zmq_tools.set_zmq_sock_options @sock, @options

      @poller = ZMQ::Poller.new
      @poller.register_readable @sock

      @sock.connect @addr

      ready = Util.wait_t
      @thread = Thread.new do
        next_state :RUNNING
        @poller.poll(@socket_wait)
        Util.resolve_t ready, ''
        loop do
          if current_state == :DISCONNECTING
            @sock.disconnect @addr
            @socket_wait = 0
            next_state :CLOSING
          end
          if @poller.poll(@socket_wait) == 0
            if current_state == :CLOSING
              @sock.close
              break
            else
              next
            end
          end
          # RECEIVING INCOMING MESSAGE
          buffers = []
          @sock.recv_strings buffers, ZMQ::DONTWAIT
          id, *frames = buffers
          parsed = Zmq_tools.parse_input frames

          response = begin
            returned = @handler.(parsed)
            unless returned.respond_to?(:serialize)
              raise NewqueError.new "Block given to Fifo_client.connect returned #{returned.class} which is not a valid response object"
            end
            serialized = returned.serialize
            messages = serialized[:messages]
            serialized.delete :messages
            {
              output: Output.new(serialized.merge!(errors: [])),
              messages: messages
            }
          rescue => handler_error
            {
              output: Output.new(errors: [handler_error.to_s], error_output: Error_Output.new),
              messages: []
            }
          end
          @sock.send_strings ([id, response[:output].encode.to_s] + response[:messages]), ZMQ::DONTWAIT

        end
        next_state :CLOSED
      end
      @thread.abort_on_exception = true
      ready
    end

    def disconnect
      state = current_state
      if state == :NEW
        nil
      elsif state == :RUNNING
        next_state :DISCONNECTING
      else
        raise NewqueError.new "Can't disconnect since the Fifo_client is currently #{state}"
      end
      nil
    end

    private

    def current_state
      STATES[@state]
    end

    def next_state should_be
      goes_to = STATES[@state + 1]
      unless goes_to == should_be
        raise NewqueError.new "Inconsistent state in Fifo_client. #{goes_to} should be #{should_be}"
      end
      @state = @state + 1
    end

  end

end
