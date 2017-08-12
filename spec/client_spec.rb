require 'newque'
require 'pry'
require './spec/helpers'

module Newque
  describe 'Client' do

    run_shared_tests = -> (name, client, channel) {
      def validate_read read, num
        expect(read.class).to eq Read_response
        expect(read.length).to eq num
        expect(read.last_id).to_not be_empty
        expect(read.last_timens).to be_a_kind_of Numeric
        expect(read.messages.size).to eq num
      end

      before(:each) do
        client.delete(channel).get
      end

      it "#{name} should write" do
        write = client.write(channel, false, ['msg1', 'msg2', Helpers.bin_str]).get
        expect(write.class).to eq Write_response
        expect(write.saved).to eq 3
      end

      it "#{name} should read nothing" do
        read = client.read(channel, "one").get
        expect(read.class).to eq Read_response
        expect(read.length).to eq 0
      end

      it "#{name} should read messages" do
        client.write(channel, false, Helpers.make_msgs(5)).get
        read = client.read(channel, "one").get
        validate_read read, 1

        read = client.read(channel, "many 3").get
        validate_read read, 3

        read = client.read(channel, "after_id #{read.last_id}").get
        validate_read read, 2
      end

      it "#{name} should read binary data correctly" do
        client.write(channel, false, [Helpers.bin_str]).get
        read = client.read(channel, "one").get
        expect(read.messages.first.length).to eq Helpers.bin_str.length
        expect(read.messages.first).to eq Helpers.bin_str
      end

      it "#{name} should count" do
        count = client.count(channel).get
        expect(count.class).to eq Count_response
        expect(count.count).to eq 0

        client.write(channel, false, Helpers.make_msgs(5)).get
        count = client.count(channel).get
        expect(count.class).to eq Count_response
        expect(count.count).to eq 5
      end

      it "#{name} should check health" do
        health = client.health(channel).get
        expect(health.class).to eq Health_response
      end

      it "#{name} should check health globally" do
        health = client.health(channel, true).get
        expect(health.class).to eq Health_response
      end

      it "#{name} should support concurrent calls" do
        write1 = client.write(channel, false, Helpers.make_msgs(5))
        write2 = client.write(channel, false, Helpers.make_msgs(3))

        expect(write2.get.saved).to eq 3
        expect(write1.get.saved).to eq 5
      end

      it "#{name} should pass errors" do
        write = client.write('invalid_channel', false, Helpers.make_msgs(5))
        expect { write.get }.to raise_error NewqueError
      end
    }

    host = '127.0.0.1'
    timeout = 3000
    zmq_client = Client.new(:zmq, host, 8005, timeout:timeout)
    http_json_client = Client.new(:http, host, 8000, timeout:timeout)
    http_plaintext_client = Client.new(:http, host, 8000, protocol_options:{http_format: :plaintext}, timeout:timeout)

    run_shared_tests.('ZMQ', zmq_client, 'example')
    run_shared_tests.('HTTP JSON', http_json_client, 'example')
    run_shared_tests.('HTTP Plaintext', http_plaintext_client, 'example_plaintext')

    describe 'HTTP-specific' do
      run_http_tests = -> (name, client, channel) {
        it "#{name} should support Read Stream" do
          client.delete(channel).get
          num_batches = 25
          batch_size = 100
          num_batches.times do |i|
            write = client.write(channel, false, Helpers.make_msgs(batch_size, from:(i*batch_size))).get
            expect(write.saved).to eq batch_size
          end

          counter = 0
          # TODO: Fix Limit
          enum = client.read_stream channel, "many #{num_batches * batch_size}" #, limit:100
          enum.each.with_index do |x, i|
            expect("msg#{i}").to eq x
            counter = counter + 1
          end
          expect(counter).to eq(num_batches * batch_size)
        end
      }

      run_http_tests.('HTTP JSON', http_json_client, 'example')
      run_http_tests.('HTTP Plaintext', http_plaintext_client, 'example_plaintext')
    end
  end

end
