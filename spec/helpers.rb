module Newque
  class Helpers
    def self.make_msgs num, from:0
      (from..(from + num - 1)).to_a.map { |x| "msg#{x}"}
    end
  end
end
