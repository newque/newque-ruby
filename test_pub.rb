require './newque'

newque_zmq = Newque::Client.new :zmq, '127.0.0.1', 8005

i = 1

while true do
  newque_zmq.write 'example_pubsub', false, ['abcdef', i.to_s]
  puts i
  i = i + 1
  sleep 1
end
