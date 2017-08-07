module Newque

  class Util

    def self.compute_options base_options, options
      Hash[
        base_options.map do |name, default_value|
          [name, (options[name].nil? ? default_value : options[name])]
        end
      ]
    end

    def self.time_ms
      (Time.now.to_f * 1000).to_i
    end

    def self.newque_error errors
      NewqueError.new "Client Error#{errors.size > 1 ? 's' : ''}: #{errors.join(', ')}"
    end

    def self.zmq_error error
      NewqueError.new "Network Error: #{error}"
    end

    def self.wait_t
      t = Thread.new do
        while Thread.current.thread_variable_get(:result).nil?
          sleep 0
        end
        Thread.current.thread_variable_get(:result)
      end
      t.priority = -1
      t
    end

    def self.resolve_t thread, result
      thread.thread_variable_set(:result, result)
    end

  end

end