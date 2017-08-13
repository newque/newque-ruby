# Newque-ruby

Official gem for [Newque](https://github.com/newque/newque). It offers a high level interface that is fully asynchronous and non-blocking.

See the [Newque documentation](https://github.com/newque/newque) for more information about configuring Newque for your use case.

## Install
Requirements:

- libffi
- libzmq

Mac:
```bash
brew install libffi zeromq
```
Linux:
```bash
sudo apt-get install libffi-dev libzmq5
```

Then add `gem 'newque'` to your Gemfile.

## Client
A Client is the main way to interact with Newque. Clients can send requests to Newque (Write, Read, Count, etc.) and receive responses for those requests. Every operation is *concurrent*, meaning that you can send multiple requests at the same time and wait until they all complete. These requests will be executing in parallel in the background. Read the short [Newque-Ruby Concurrency Guide](#newque-ruby-concurrency-guide) for a refresher on concurrency in Ruby.

```ruby
Newque::Client.new(protocol, host, port, protocol_options:, timeout:)
```
```ruby
# Example values
client = Newque::Client.new(:http, '127.0.0.1', 8005, protocol_options:{https: true}, timeout:5000)
```
These 3 arguments are required:
- **protocol**: (`:zmq` or `:http`) Must match the protocol used by the Newque server.
- **host**: (`String`) Hostname/IP address of the Newque server.
- **port**: (`Integer`) Port of the Newque server.

Additionally, you can supply these optional named arguments:
- **protocol_options**: (`Hash`) Optional named argument. The valid options depend on the `protocol` being used. See [ZMQ Options](#zmq-options) and [HTTP Options](#http-options).
- **timeout** (`Integer`) Optional named argument. Number of milliseconds to wait before cancelling for an operation to receive a response from the server. `10000` by default. At the moment only HTTP uses this value. Since all operations return Threads, it's also possible to use Ruby's `.join(1)` on a response thread to wait for 1 second. [Newque-Ruby Concurrency Guide](#newque-ruby-concurrency-guide)

### Client methods

#### .write
```ruby
result = client.write(channel, atomic, messages)
result.value # => waits until the call completes and returns a Newque::Write_Response
```
- **channel** (`String`) Name of the channel.
- **atomic** (`Bool`) Whether the messages should be treated as one.
- **messages** (`Array` of `String`s) The messages to send.

Returns a `Future`. The value returned by the Future will be a [`Newque::Write_Response`](#write_response).

#### .read
```ruby
result = client.read(channel, mode, limit)
result.value # => waits until the call completes and returns a Newque::Read_Response
```
- **channel** (`String`) Name of the channel.
- **mode** (`String`) Newque Reading Mode.
- **limit** (Optional `Integer`) The maximum number of messages to receive. `nil` by default.

Returns a `Future`. The value returned by the Future will be a [`Newque::Read_Response`](#read-response).

#### .read_stream
```ruby
enumerable = client.read_stream(channel, mode, limit)
```
- **channel** (`String`) Name of the channel.
- **mode** (`String`) Newque Reading Mode.
- **limit** (Optional `Integer`) The maximum number of messages to receive. `nil` by default.

Not available on `:zmq` clients! It takes the same arguments as `read` and returns a Lazy Enumerable. It'll stream the messages from Newque only when requested, for example by doing `.each` or any other standard method supported by Enumerables. It only holds a small number of messages at a time in memory (configurable on the server), making this a convenient way to iterate through a large dataset without having to make multiple `read` calls. It uses HTTP's `Transfer-Encoding: Chunked`. For obvious reasons it's not possible to know how many messages will be returned until the stream is exhausted by iterating through the entire Enumerable.

#### .count
```ruby
result = client.count(channel)
result.value # => waits until the call completes and returns a Newque::Count_Response
```
- **channel** (`String`) Name of the channel.

Returns a `Future`. The value returned by the Future will be a [`Newque::Count_Response`](#count-response).

#### .delete
```ruby
result = client.delete(channel)
result.value # => waits until the call completes and returns a Newque::Delete_Response
```
- **channel** (`String`) Name of the channel.

Returns a `Future`. The value returned by the Future will be a [`Newque::Delete_Response`](#delete-response).

#### .health
```ruby
result = client.health(channel, global)
result.value # => waits until the call completes and returns a Newque::Health_Response
```
- **channel** (`String`) Name of the channel.
- **global** (`Bool`) Whether this health check should check all the channels on the server or just this one.

Returns a `Future`. The value returned by the Future will be a [`Newque::Health_Response`](#health-response).

## Pubsub Client
A Pubsub Client is a special type of client that can listen to requests coming from a Newque Pubsub endpoint. These Pubsub Clients are the subscribers. It's possible to have any number of Pubsub Clients active at any time.
```ruby
consumer = Newque::Pubsub_client.new(host, port, protocol_options:, socket_wait:)
```
The first 4 arguments are identical to a normal [Client](#client).

**socket_wait**: (`Integer`) Optional named argument. This is the maximum acceptable time it could take to disconnect from the server. `100` (ms) by default.

#### .subscribe
This is the main operation on a Pubsub Client.
```ruby
ready = consumer.subscribe do |input|
  input.messages # => ['msg1', 'msg2']
  input.action # => Newque::Write_request or Newque::Read_request, etc.
end

sub_id = ready.value # Waits until we are connected and returns the sub_id
```
Each time a request is sent to the Pubsub endpoint, this block will be invoked. The `input` argument is an [Input_request](#input-request).

`.subscribe` takes a block and returns a Future that evaluates to a Subscription ID. That Sub ID can then be given to `.unsubscribe` later to deactivate this specific block.

The Future that was returned by `.subscribe` does not resolve until the block is actively listening, which can take a few milliseconds.

It's possible to call `.subscribe` on the same Pubsub Client many times to register multiple blocks. A Pubsub Client doesn't open a connection to the server until a block is registered.

#### .unsubscribe
```ruby
consumer.unsubscribe(sub_id)
```
Removes the block passed earlier from the list of subscribers.

#### .add_error_handler
```ruby
consumer.add_error_handler do |error|
  # Do something with error
end
```
`.add_error_handler` takes a single block and can be called multiple times to register multiple blocks. When exceptions are raised inside of a subscribed block they are passed to this error handling block. If no error handler is present when an exception is raised, it'll be printed using `puts`, so register an error handler if you wish to avoid this behavior!

#### .disconnect
```ruby
consumer.disconnect
```
Disconnects the Pubsub Client within `socket_wait` milliseconds. All subscribed blocks are still present. To reconnect, simply `.subscribe` a new block (you can unsubscribe it later).

## Fifo Client
A Fifo Client is a special type of client that can listen to requests coming from a Newque Fifo endpoint and send responses back! It's possible to have any number of Fifo Clients active at any time.
```ruby
consumer = Newque::Fifo_client.new(host, port, protocol_options:, socket_wait:)
```
The first 4 arguments are identical to a normal [Client](#client).

**socket_wait**: (`Integer`) Optional named argument. This is the maximum acceptable time it could take to disconnect from the server. `100` (ms) by default.

#### .connect
This is the main operation on a Fifo Client.
```ruby
ready = consumer.connect do |input|
  input.channel # => 'my_channel'
  input.messages # => ['msg1', 'msg2']
  input.action # => Newque::Write_request or Newque::Read_request, etc.

  # If `input.action` was a Newque::Write_request, then I must return a Newque::Write_response
  Newque::Write_response.new(5)
end

ready.join # Only needed if we wish to wait until the Fifo Client is ready
```
`.connect` takes a block that receives and processes [Requests](#input-request). That block must return a [Response object](#response-objects) that matches the type of the Request! Calling `input.action.class` is an easy to find out the type of the request.

To return an error to the client that sent the request to Newque, just raise an exception from within the block!

`.connect` returns a Future that resolves once the Fifo Client is fully connected. Calling `.connect` on a Fifo Client that is already connected will raise an exception.

#### .disconnect
```ruby
consumer.disconnect
```
Disconnects the Fifo Client within `socket_wait` milliseconds. A Fifo Client can't be reconnected, make a new one instead.

## Newque-Ruby Concurrency Guide
The [Thread](https://ruby-doc.org/core-2.2.0/Thread.html) is Ruby's basic concurrency primitive. There is never more than one Ruby Thread executing Ruby code at any moment, but native extensions given their own Thread can continue running in the background while executing native (non-Ruby) code.

Newque-Ruby makes heavy use of Threads, since for example, a Pubsub Client waiting for requests should not "take up" your only allowed active Ruby Thread!

Most method calls on Newque-Ruby return a `Future`, which is just a simple object to manage the underlying Ruby Thread. If you are familiar with Promises in other languages, the Future objects returned by Newque-Ruby are very similar.

Most gems simply block and assume the user will wrap those blocking calls in a `Thread.new` if they feel brave. Due to the fact that a Newque::Client with ZMQ uses a single multiplexing connection (unlike HTTP) and that we want operations (writes, reads, etc.) -which can terminate in a different order- to be executed in parallel, Newque-Ruby operations have to return Futures that will *resolve* to the desired result. In order to keep Newque::Clients with HTTP identical to ZMQ ones, those return Futures too.

**What you need to know:**

To get the result of an operation, you have to call `.get` on the Future returned by Newque-Ruby.

- `client.delete('mychannel').get(limit)` will wait for the Future returned by `.delete` to resolve for up to `limit` seconds. If it times out, `.get` will raise `Timeout::Error`.
- The `limit` argument is optional, it defaults to the `timeout` value passed when creating the Client.

```ruby
future1 = client.write('channel_a', false, ['msg1'])
future2 = client.write('channel_b', false, ['msg1'])

result1 = future1.get
result2 = future1.get

# Do something with the results
```
This snippet makes 2 calls in parallel and waits until both have completed to continue.

## Protocol Options

### HTTP Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `https` | `Bool` | No | `false` | Whether to use HTTPS or not. |
| `http_format` | `:json` or `:plaintext` | No | `:json` | Must match the HTTP Format configured in Newque. `json` by default. |
| `separator` | `String` | No | `"\n"` | Must match the separator string configured in Newque. `"\n"` by default. |

### ZMQ Options

(**IMPORTANT:** Read [the docs](http://api.zeromq.org/4-0:zmq-setsockopt) before changing any defaults!)

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `ZMQ_MAXMSGSIZE` | Integer | No | `-1` | Max message size in bytes, `-1` means unlimited. |
| `ZMQ_LINGER` | Integer | No | `60000` | How long to keep unaccepted messages after disconnection in milliseconds. |
| `ZMQ_RECONNECT_IVL` | Integer | No | `100` | Reconnection interval in milliseconds. |
| `ZMQ_RECONNECT_IVL_MAX` | Integer | No | `60000` | Max exponential backoff reconnection interval in milliseconds. |
| `ZMQ_BACKLOG` | Integer | No | `100` | The `backlog` argument for the `listen(2)` syscall. |
| `ZMQ_SNDHWM` | Integer | No | `5000` | Hard limit on the number outbound outstanding messages per connection. |
| `ZMQ_RCVHWM` | Integer | No | `5000` | Hard limit on the number inbound outstanding messages per connection. |

## Response objects

These objects are returned by method calls on a `Newque::Client`. Additionally, they are what a `Newque::Fifo_client` must return to the server.

#### Write_response
```ruby
response = Newque::Write_response.new(5)
response.saved # => 5
```

#### Read_response
```ruby
response = Newque::Read_response.new(2, 'some-id', 12345678, ['msg1', 'msg2'])
response.length # => 2
response.last_id # => 'some-id'
response.last_timens # => '12345678'
response.messages # => ['msg1', 'msg2']
```

#### Count_response
```ruby
response = Newque::Count_response.new(8)
response.count # => 8
```

#### Delete_response
```ruby
response = Newque::Delete_response.new
```

#### Health_response
```ruby
response = Newque::Health_response.new
```

## Request objects

`Newque::Fifo_client`s and `Newque::Pubsub_client`s receive an `Input_request` when a request is received on a channel with Backend of that type.

#### Input_request

```ruby
request.channel # => 'my_channel'
request.messages # => ['msg1', 'msg2']
request.action # => Newque::Write_request or Newque::Read_request, etc.
```

#### Write_request
```ruby
request = Newque::Write_request.new(false, ['id1', 'id2'])
request.atomic # => false
request.ids # => ['id1', 'id2']
```

#### Read_request
```ruby
request = Newque::Read_request.new('after_id some-id', '100')
request.mode # => 'after_id some-id'
request.limit # => 100
```

#### Count_request
```ruby
request = Newque::Count_request.new
```

#### Delete_request
```ruby
request = Newque::Delete_request.new
```

#### Health_request
```ruby
request = Newque::Health_request.new(false)
request.global # => false
```

## Running the tests
Make sure the Gem dev dependencies are installed first.

You'll need 2 terminals windows!
```bash
# In terminal 1
docker pull newque/newque:v0.0.5

docker run -it -p 8000:8000 -p 8001:8001 -p 8005:8005 -p 8006:8006 -p 8007:8007 newque/newque:v0.0.5 bash
cd newque
rm -r conf

# Switch to terminal 2

# Grab the Container ID:
docker ps

# Replace the CONTAINER_ID in this command and make sure you're in the newque-ruby/ directory:
docker cp conf CONTAINER_ID:/newque/conf

# Go back to terminal 1
./newque

# Switch to terminal 2
bundle exec rake
```
