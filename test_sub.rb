require './newque'

newque_pubsub = Pubsub_client.new '127.0.0.1', 8006

def print_stuff stuff
  # binding.pry
  puts stuff.to_s
end

newque_pubsub.unsubscribe "abc"

newque_pubsub.subscribe("abc", &method(:print_stuff))

puts "doing stuff"

sleep 2

puts "still doing stuff"

newque_pubsub.unsubscribe "abc"

sleep 2

puts "let's connect 2!"
newque_pubsub.subscribe("abc", &method(:print_stuff))
newque_pubsub.subscribe("def", &method(:print_stuff))

sleep 2

puts "disconnecting 1.."

newque_pubsub.unsubscribe "def"

sleep 2

puts "bye"
