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
  write = newque.write channel, false, ['msg1', 'msg2', bin_str]
  puts write

  read = newque.read channel, "many 100"
  raise "Should match" unless read.messages[2] == bin_str
  puts read
  if newque.protocol == :http
    enum = newque_http_json.read_stream channel, 'many 100'
    raise "Stream should match" unless (enum.to_a == read.messages)
  end

  count = newque.count channel
  puts count

  health = newque.health channel
  puts health

  health = newque.health channel, true
  puts health

  delete = newque.delete channel
  puts delete
end
