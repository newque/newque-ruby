require 'bundler/setup'
require 'ffi-rzmq'
require 'beefcake'
require 'securerandom'

require 'pry'

require './lib/errors'
require './lib/protobuf'
require './lib/responses'
require './lib/newque_zmq'

class Newque
  extend Forwardable

  def_delegators :@instance, :write, :read, :count, :delete, :health

  def initialize protocol, host, port, protocol_options:nil, timeout:10000
    @instance = if protocol == :zmq
      Newque_zmq.new host, port, (protocol_options || Newque_zmq::BASE_OPTIONS), timeout
    elsif protocol == :http
      Newque_http.new host, port, (protocol_options || Newque_http::BASE_OPTIONS), timeout
    else
      raise NewqueError.new "Invalid protocol [#{protocol}]. Must be either :zmq or :http"
    end
  end

end
