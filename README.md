# Newque-ruby

Official gem for [Newque](https://github.com/newque/newque). It offers a high level interface that is fully asynchronous and non-blocking.

See the [Newque documentation](https://github.com/newque/newque) for more information about configuring Newque for your use case.

## Client

```ruby
Newque::Client.new(protocol, host, port, protocol_settings:, timeout:)
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
- **protocol_options**: (`Hash`) Optional named argument. The valid options depend on the `protocol` being used.
For `:http`, they are:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `https` | `Bool` | No | `false` | Whether to use HTTPS or not. |
| `http_format` | `:json` or `:plaintext` | No | `:json` | Must match the HTTP Format configured in Newque. `json` by default. |
| `separator` | `String` | No | `"\n"` | Must match the separator string configured in Newque. `"\n"` by default. |

For `:zmq`, they are:

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

- **timeout** (`Integer`) Number of milliseconds to wait before cancelling for an operation to receive a response from the server. `10000` by default. At the moment only HTTP uses this value. Since all operations return Threads, it's also possible to use Ruby's `.join(1).value` on a response thread to wait for 1 second.

### Client methods

#### .write
```ruby
result = client.write(channel, atomic, messages)
result.value # => waits until the call completes and returns a Newque::Write_Response

```
- **channel** (`String`) Name of the channel.
- **atomic** (`Bool`) Whether the messages should be treated as one.
- **messages** (`Array` of `String`s) The messages to send.

Returns a `Thread`. The value returned by the thread will be a [`Newque::Write_Response`](#write_response).

#### .read
```ruby
result = client.read(channel, mode, limit)
result.value # => waits until the call completes and returns a Newque::Read_Response

```
- **channel** (`String`) Name of the channel.
- **mode** (`String`) Newque Reading Mode.
- **limit** (Optional `Integer`) The maximum number of messages to receive. `nil` by default.

Returns a `Thread`. The value returned by the thread will be a [`Newque::Read_Response`](#read-response).

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

Returns a `Thread`. The value returned by the thread will be a [`Newque::Count_Response`](#count-response).

#### .delete
```ruby
result = client.delete(channel)
result.value # => waits until the call completes and returns a Newque::Delete_Response

```
- **channel** (`String`) Name of the channel.

Returns a `Thread`. The value returned by the thread will be a [`Newque::Delete_Response`](#delete-response).

#### .health
```ruby
result = client.health(channel, global)
result.value # => waits until the call completes and returns a Newque::Health_Response

```
- **channel** (`String`) Name of the channel.
- **global** (`Bool`) Whether this health check should check all the channels on the server or just this one.

Returns a `Thread`. The value returned by the thread will be a [`Newque::Health_Response`](#health-response).

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

These objects are given to `Newque::Fifo_client`s and `Newque::Pubsub_client`s when a request is received on a channel with Backend of that type.

#### Write_request
```ruby
request = Newque::Write_request.new(false, ['id1', 'id2'])
request.atomic # => false
request.ids # => ['id1', 'id2']
request.messages # => an array of messages
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
