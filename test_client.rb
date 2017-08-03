require './newque'

newque_zmq = Client.new :zmq, '127.0.0.1', 8005
newque_http_plaintext = Client.new :http, '127.0.0.1', 8000, protocol_options:{http_format: :plaintext}
newque_http_json = Client.new :http, '127.0.0.1', 8000

bin_str = (0..127).to_a.pack('c*').gsub("\n", "")
[
  [newque_http_plaintext, 'example_plaintext'],
  [newque_http_json, 'example'],
  [newque_zmq, 'example']
].each do |newque, channel|
  begin
    write = newque.write channel, false, ['msg1', 'msg2', bin_str]
    puts write
  rescue => e
    puts e.to_s
  end

  begin
    read = newque.read channel, "many 100"
    raise "Should match" unless read.messages[2] == bin_str
    puts read
  rescue => e
    puts e.to_s
  end

  begin
    count = newque.count channel
    puts count
  rescue => e
    puts e.to_s
  end

  begin
    health = newque.health channel
    puts health
  rescue => e
    puts e.to_s
  end

  begin
    health = newque.health channel, true
    puts health
  rescue => e
    puts e.to_s
  end

  begin
    delete = newque.delete channel
    puts delete
  rescue => e
    puts e.to_s
  end
end
