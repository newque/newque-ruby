require 'ffi-rzmq'

module Newque

  class Zmq_tools

    BASE_OPTIONS = {
      ZMQ_MAXMSGSIZE: -1,
      ZMQ_LINGER: 60000,
      ZMQ_RECONNECT_IVL: 100,
      ZMQ_RECONNECT_IVL_MAX: 60000,
      ZMQ_BACKLOG: 100,
      ZMQ_RCVHWM: 5000
    }
    # BASE_OPTIONS, with the values being the ZMQ constants for those options
    ZMQ_OPT_MAPPING = Hash[
        BASE_OPTIONS.map do |name, value|
        [name, ZMQ.const_get(name.to_s.slice(4..-1))]
      end
    ]

    def self.set_zmq_sock_options sock, options
      options.each do |name, value|
        sock.setsockopt ZMQ_OPT_MAPPING[name], value
      end
    end

  end

end
