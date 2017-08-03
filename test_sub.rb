require './newque'

newque_pubsub = Pubsub_client.new '127.0.0.1', 8006

def print_stuff stuff
  # binding.pry
  puts stuff.to_s
end

newque_pubsub.unsubscribe

t = newque_pubsub.subscribe(&method(:print_stuff))

puts "doing stuff"

sleep 3

puts "still doing stuff"

newque_pubsub.unsubscribe

sleep 2

puts "let's reconnect!"
t = newque_pubsub.subscribe(&method(:print_stuff))

sleep 2

puts "bye"