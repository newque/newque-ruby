# ------------------------------------
# REQUEST OBJECTS

class Write_Input
  include Beefcake::Message
  optional :atomic, :bool, 1
  repeated :ids, :bytes, 2
end

class Read_Input
  include Beefcake::Message
  required :mode, :bytes, 1
  optional :limit, :int64, 2
end

class Count_Input
  include Beefcake::Message
end

class Delete_Input
  include Beefcake::Message
end

class Health_Input
  include Beefcake::Message
  required :global, :bool, 1
end

class Input
  include Beefcake::Message
  required :channel, :bytes, 1
  optional :write_input, Write_Input, 11
  optional :read_input, Read_Input, 12
  optional :count_input, Count_Input, 13
  optional :delete_input, Delete_Input, 14
  optional :health_input, Health_Input, 15
end

# ------------------------------------
# RESPONSE OBJECTS

class Error_Output
  include Beefcake::Message
end

class Write_Output
  include Beefcake::Message
  optional :saved, :int32, 1
end

class Read_Output
  include Beefcake::Message
  required :length, :int32, 1
  optional :last_id, :bytes, 2
  optional :last_timens, :int64, 3
end

class Count_Output
  include Beefcake::Message
  optional :count, :int64, 1
end

class Delete_Output
  include Beefcake::Message
end

class Health_Output
  include Beefcake::Message
end

class Output
  include Beefcake::Message
  repeated :errors, :bytes, 1
  optional :error_output, Error_Output, 11
  optional :write_output, Write_Output, 12
  optional :read_output, Read_Output, 13
  optional :count_output, Count_Output, 14
  optional :delete_output, Delete_Output, 15
  optional :health_output, Health_Output, 16
end

# ------------------------------------
# WRAPPERS

class Many
  include Beefcake::Message
  repeated :buffers, :bytes, 1
end

# ------------------------------------
