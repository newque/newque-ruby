require 'newque'
require 'pry'
require './spec/helpers'

module Newque
  describe 'Pubsub_client' do
    let(:channel) { 'example_pubsub' }

    before(:each) do
      @producer1 = Client.new(:http, '127.0.0.1', 8000)
      @producer2 = Client.new(:zmq, '127.0.0.1', 8005)
      @consumer1 = Pubsub_client.new '127.0.0.1', 8006
      @consumer2 = Pubsub_client.new '127.0.0.1', 8006
    end

    it 'subscribes' do
      thread1 = Util.wait_t
      thread2 = Util.wait_t

      received1 = []
      received2 = []
      should_receive = []
      num_sent = 10
      ready1 = @consumer1.subscribe { |input|
        raise unless input.class == Input_request
        raise unless input.action.class == Write_request
        raise unless input.action.ids.size == input.messages.size
        received1.concat input.messages
        Util.resolve_t(thread1, '') if received1.size == (num_sent * 2)
      }
      ready2 = @consumer2.subscribe { |input|
        raise unless input.class == Input_request
        raise unless input.action.class == Write_request
        raise unless input.action.ids.size == input.messages.size
        received2.concat input.messages
        Util.resolve_t(thread2, '') if received2.size == (num_sent * 2)
      }
      ready1.join
      ready2.join

      num_sent.times do |i|
        @producer1.write(channel, false, [i.to_s]).join
        @producer2.write(channel, false, [i.to_s]).join
        2.times { should_receive << i.to_s }
      end

      thread1.join(1)
      thread2.join(1)
      expect(received1.sort).to eq should_receive.sort
      expect(received2.sort).to eq should_receive.sort
    end

    it 'catches exceptions' do
      thread = Util.wait_t
      ready1 = @consumer1.subscribe {
        raise 'BOOM'
      }
      ready1.join
      @consumer1.add_error_handler do |error|
        Util.resolve_t(thread, error.to_s)
      end
      @producer1.write(channel, false, ['stuff']).join
      thread.join(1)
      expect(thread.value).to eq 'BOOM'
    end

    it 'unsubscribes and resubscribes' do
      received = []
      thread = Util.wait_t

      # Subscribe
      ready = @consumer1.subscribe do |input|
        received << input.messages.first
        Util.resolve_t thread, input.messages.first
      end
      id = ready.value

      # Message 1
      @producer1.write(channel, false, ['MSG1']).join
      expect(thread.value).to eq 'MSG1'

      # Unsubscribe
      thread = Util.wait_t
      @consumer1.unsubscribe id

      # Message 2
      @producer1.write(channel, false, ['MSG2']).join
      expect(thread.join(1)).to be_nil # nothing was received

      # Resubscribe
      ready = @consumer1.subscribe do |input|
        received << input.messages.first
        Util.resolve_t thread, input.messages.first
      end
      ready.join

      # Message 3
      @producer1.write(channel, false, ['MSG3']).join
      expect(thread.value).to eq 'MSG3'
      expect(received).to eq ['MSG1', 'MSG3']
    end

    it 'disconnects' do
      received = []
      thread1 = Util.wait_t

      # Subscribe
      ready = @consumer1.subscribe do |input|
        received << "FROM_1 #{input.messages.first}"
        Util.resolve_t thread1, input.messages.first
      end
      id = ready.value

      # Message 1
      @producer1.write(channel, false, ['MSG1']).join
      expect(thread1.value).to eq 'MSG1'

      # Disconnect
      thread2 = Util.wait_t
      @consumer1.disconnect

      # Message 2
      @producer1.write(channel, false, ['MSG2']).join
      expect(thread2.join(1)).to be_nil # nothing was received

      # Reconnect and Resubscribe
      ready = @consumer2.subscribe do |input|
        received << "FROM_2 #{input.messages.first}"
        Util.resolve_t thread2, input.messages.first
      end
      ready.join

      # Message 3
      @producer1.write(channel, false, ['MSG3']).join
      expect(thread2.value).to eq 'MSG3'
      expect(received.sort).to eq ['FROM_1 MSG1', 'FROM_1 MSG2', 'FROM_2 MSG3']
    end

  end
end
