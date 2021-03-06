require 'json'

module Newque

  # ------------------------------------
  # REQUESTS
  # ------------------------------------
  class Write_request
    attr_reader :atomic, :ids

    def initialize atomic, ids
      @atomic = atomic
      @ids = ids
    end

    def to_s
      "<Write atomic: #{@atomic.to_json} ids: #{@ids.to_json}>"
    end

    def inspect
      to_s
    end
  end

  class Read_request
    attr_reader :mode, :limit

    def initialize mode, limit
      @mode = mode
      @limit = limit
    end

    def to_s
      "<Read mode: #{@mode.to_json} limit: #{@limit.to_json}>"
    end

    def inspect
      to_s
    end
  end

  class Count_request
    def initialize
    end

    def to_s
      "<Count >"
    end

    def inspect
      to_s
    end
  end

  class Delete_request
    def initialize
    end

    def to_s
      "<Delete >"
    end

    def inspect
      to_s
    end
  end

  class Health_request
    attr_reader :global

    def initialize global
      @global = global
    end

    def to_s
      "<Health global: #{@global.to_json}>"
    end

    def inspect
      to_s
    end
  end

  class Input_request
    attr_reader :channel, :action, :messages

    def initialize channel, action, messages
      @channel = channel
      @action = action
      @messages = messages
    end

    def to_s
      "<Newque_input channel: #{channel.to_json} action: #{@action} #{@messages.size > 0 ? 'messages: ' + @messages.to_json : ''}>"
    end

    def inspect
      to_s
    end
  end

  # ------------------------------------
  # RESPONSES
  # ------------------------------------
  class Write_response
    attr_reader :saved

    def initialize saved
      @saved = saved
    end

    def to_s
      "<Newque_write saved: #{saved.to_json}>"
    end

    def inspect
      to_s
    end

    def serialize
      {
        write_output: Write_Output.new(saved: @saved),
        messages: []
      }
    end
  end

  class Read_response
    attr_reader :length, :last_id, :last_timens, :messages

    def initialize length, last_id, last_timens, messages
      @length = length
      @last_id = last_id
      @last_timens = last_timens
      @messages = messages
    end

    def to_s
      "<Newque_read length: #{length.to_json} last_id: #{last_id.to_json} last_timens: #{last_timens.to_json} messages: #{messages}>"
    end

    def inspect
      to_s
    end

    def serialize
      {
        read_output: Read_Output.new(length: @length, last_id: @last_id, last_timens: @last_timens),
        messages: @messages
      }
    end
  end

  class Count_response
    attr_reader :count

    def initialize count
      @count = count
    end

    def to_s
      "<Newque_count count: #{count.to_json}>"
    end

    def inspect
      to_s
    end

    def serialize
      {
        count_output: Count_Output.new(count: @count),
        messages: []
      }
    end
  end

  class Delete_response

    def initialize
    end

    def to_s
      "<Newque_delete >"
    end

    def inspect
      to_s
    end

    def serialize
      {
        delete_output: Delete_Output.new,
        messages: []
      }
    end
  end

  class Health_response

    def initialize
    end

    def to_s
      "<Newque_health >"
    end

    def inspect
      to_s
    end

    def serialize
      {
        health_output: Health_Output.new,
        messages: []
      }
    end
  end

end
