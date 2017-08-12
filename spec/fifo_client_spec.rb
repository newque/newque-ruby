require 'newque'
require 'pry'
require './spec/helpers'

module Newque
  describe 'Fifo_client' do
    let(:channel) { 'example_fifo' }

    before(:each) do
      host = '127.0.0.1'
      timeout = 3000
      @producer1 = Client.new(:zmq, host, 8005, timeout:timeout)
      @consumer1 = Fifo_client.new host, 8007
      @consumer2 = Fifo_client.new host, 8007
    end

    after(:each) do
      @consumer1.disconnect
      @consumer2.disconnect
    end

    it 'should write' do
      messages = ['msg1', 'msg2']
      ready = @consumer1.connect do |input|
        expect(input.channel).to eq channel
        expect(input.action.class).to eq Write_request
        expect(input.action.ids.size).to eq messages.size
        expect(input.messages).to eq messages
        Write_response.new 9
      end

      ready.get
      write = @producer1.write(channel, false, messages).get
      expect(write.saved).to eq 9
    end

    it 'should read' do
      should_receive = ['msg1', 'msg2']
      ready = @consumer1.connect do |input|
        expect(input.channel).to eq channel
        expect(input.action.class).to eq Read_request
        expect(input.action.mode).to eq 'Many 2'
        expect(input.action.limit).to eq 2
        Read_response.new 2, 'some_id', 12345, ['msg123', 'msg456']
      end

      ready.get
      read = @producer1.read(channel, 'many 2').get
      expect(read.length).to eq 2
      expect(read.last_id).to_not be_empty
      expect(read.last_timens).to be_a_kind_of Numeric
      expect(read.messages.size).to eq 2
    end

    it 'should count' do
      ready = @consumer1.connect do |input|
        expect(input.channel).to eq channel
        expect(input.action.class).to eq Count_request
        Count_response.new 8
      end

      ready.get
      count = @producer1.count(channel).get
      expect(count.count).to eq 8
    end

    it 'should delete' do
      ready = @consumer1.connect do |input|
        expect(input.channel).to eq channel
        expect(input.action.class).to eq Delete_request
        Delete_response.new
      end

      ready.get
      @producer1.delete(channel).get
    end

    it 'should check health' do
      ready = @consumer1.connect do |input|
        expect(input.channel).to eq channel
        expect(input.action.class).to eq Health_request
        expect(input.action.global).to eq false
        Health_response.new
      end

      ready.get
      health = @producer1.health(channel, true).get
    end

    it 'should not be connected twice' do
      expect {
        ready = @consumer1.connect { puts; }
        ready.get
      }.to_not raise_error

      expect {
        # We're already connected
        @consumer1.connect { puts; }
      }.to raise_error NewqueError
    end

    it 'should not accept invalid response types' do
      ready = @consumer1.connect do |input|
        expect(input.channel).to eq channel
        expect(input.action.class).to eq Count_request
        'SOME STRING'
      end

      ready.get
      expect {
        @producer1.count(channel).get
      }.to raise_error NewqueError
    end

    it 'should not accept incorrect responses' do
      ready = @consumer1.connect do |input|
        expect(input.channel).to eq channel
        expect(input.action.class).to eq Count_request
        Delete_response.new
      end

      ready.get
      expect {
        @producer1.count(channel).get
      }.to raise_error NewqueError
    end


  end
end
