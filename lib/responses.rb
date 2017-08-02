class Write_response
  attr_reader :saved

  def initialize saved
    @saved = saved
  end

  def to_s
    "<Newque_write: saved=#{saved}>"
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
    "<Newque_read: length=#{length} last_id=#{last_id} last_timens=#{last_timens} messages=#{messages}>"
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
    "<Newque_count: count=#{count}>"
  end

  def inspect
    to_s
  end
end

class Delete_response

  def initialize
  end

  def to_s
    "<Newque_delete: >"
  end

  def inspect
    to_s
  end
end

class Health_response

  def initialize
  end

  def to_s
    "<Newque_health: >"
  end

  def inspect
    to_s
  end
end
