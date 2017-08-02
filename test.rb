require './newque'

newque = Newque.new :zmq, "127.0.0.1", 8005, protocol_options:{ZMQ_LINGER: 5555}, timeout:2000

begin
  write = newque.write "example", false, ["msg1"]
  puts write
rescue => e
  puts e.to_s
end

begin
  read = newque.read "example", "many 100"
  puts read
rescue => e
  puts e.to_s
end

begin
  count = newque.count "example"
  puts count
rescue => e
  puts e.to_s
end

begin
  health = newque.health "example"
  puts health
rescue => e
  puts e.to_s
end

begin
  delete = newque.delete "example"
  puts delete
rescue => e
  puts e.to_s
end
