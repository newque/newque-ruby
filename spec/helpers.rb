module Newque
  class Helpers
    def self.make_msgs num, from:0
      (from..(from + num - 1)).to_a.map { |x| "msg#{x}"}
    end

    def self.bin_str
      (0..127).to_a.pack('c*').gsub("\n", "")
    end

  end
end
