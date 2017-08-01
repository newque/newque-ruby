require 'bundler/setup'
require 'ffi-rzmq'
require 'base64'
require 'securerandom'

require './protobuf'
require './errors'

class Newque
  @@ctx = ZMQ::Context.new
  attr_reader :sock

  def initialize host, port
    @sock = @@ctx.socket ZMQ::DEALER
    @sock.connect "tcp://#{host}:#{port}"
  end

  def write channel, atomic, msgs, ids=[]
    input = Input.new(channel: channel, write_input: Write_Input.new(atomic: atomic, ids: ids))
    buffers = send_request input, msgs
    output = parse_response buffers[1], :write_output
    {
      saved: output.saved
    }
  end

  def read channel, mode, limit=nil
    buffers = send_request Input.new(channel: channel, read_input: Read_Input.new(mode: mode, limit: limit))
    output = parse_response buffers[1], :read_output
    {
      length: output.length,
      last_id: output.last_id,
      last_timens: output.last_timens,
      messages: buffers.slice(2, buffers.size)
    }
  end

  def count channel
    buffers = send_request Input.new(channel: channel, count_input: Count_Input.new)
    output = parse_response buffers[1], :count_output
    {
      count: output.count
    }
  end

  def delete channel
    buffers = send_request Input.new(channel: channel, delete_input: Delete_Input.new)
    output = parse_response buffers[1], :delete_output
    {}
  end

  def health channel, global=false
    buffers = send_request Input.new(channel: channel, health_input: Health_Input.new(global: global))
    output = parse_response buffers[1], :health_output
    {}
  end

  private

  def send_request input, msgs=[]
    id = SecureRandom.uuid
    meta = input.encode.to_s
    @sock.send_strings (msgs.size > 0 ? [id, meta] + msgs : [id, meta])
    get_response id
  end

  def get_response id
    buffers = []
    begin
      @sock.recv_strings buffers
    rescue
      if buffers.size == 0
        @sock.recv_strings buffers, ZMQ::DONTWAIT
      end
    end
    raise NewqueError.new("Returned ID #{buffers[0]} doesn't match #{id}") unless buffers[0] == id
    buffers
  end

  def parse_response buffer, type
    output = Output.decode buffer
    if output.errors
      raise make_error output.errors
    end
    output.send type
  end

  def make_error errors
    NewqueError.new "Error#{errors.size > 1 ? 's' : ''}: #{errors.join(', ')}"
  end

end


newque = Newque.new "127.0.0.1", "8005"

write = newque.write "example", false, ["msg1"]
puts write.to_s

read = newque.read "example", "many 100"
puts read.to_s

count = newque.count "example"
puts count.to_s

health = newque.health "example"
puts health.to_s

delete = newque.delete "example"
puts delete.to_s
