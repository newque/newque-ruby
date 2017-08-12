module Newque

  class Future

    attr_reader :thread

    def initialize thread, timeout
      @thread = thread
      @timeout = timeout
    end

    def get limit=@timeout
      result = @thread.join(limit)
      if result.nil?
        # Timeout exceeded
        @thread.kill
        raise Timeout::Error
      end
      result.value
    end


    def to_s
      "<NewqueFuture timeout: #{@timeout} status: #{@thread.status}>"
    end

    def inspect
      to_s
    end

  end

end
