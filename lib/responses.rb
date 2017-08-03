class Write_request
  attr_reader :atomic, :ids

  def initialize atomic, ids
    @atomic = atomic
    @ids = ids
  end

  def to_s
    "<atomic: #{@atomic.to_json} ids: #{@ids.to_json}>"
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
    "<mode: #{@mode.to_json} limit: #{@limit.to_json}>"
  end

  def inspect
    to_s
  end
end

class Count_request
  def initialize
  end

  def to_s
    "<>"
  end

  def inspect
    to_s
  end
end

class Delete_request
  def initialize
  end

  def to_s
    "<>"
  end

  def inspect
    to_s
  end
end

class Health_request
  attr_reader :mode

  def initialize global
    @global = global
  end

  def to_s
    "<global: #{@global.to_json}>"
  end

  def inspect
    to_s
  end
end

class Input_request
  attr_reader :channel, :payload, :messages

  def initialize channel, payload, messages
    @channel = channel
    @payload = payload
    @messages = messages
  end

  def to_s
    "<Newque_input channel: #{channel.to_json} payload: #{@payload} #{@messages.size > 0 ? 'messages: ' + @messages.to_json : ''}>"
  end

  def inspect
    to_s
  end
end

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
    "<Newque_read length: #{length.to_json} last_id: #{last_id.to_json} last_timens: #{last_timens.to_json} messages: #{messages.to_json}>"
  end

  def inspect
    to_s
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
end
