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

  end

end