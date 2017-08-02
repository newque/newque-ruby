class NewqueError < StandardError
end

def newque_error errors
  NewqueError.new "Client Error#{errors.size > 1 ? 's' : ''}: #{errors.join(', ')}"
end

def zmq_error error
  NewqueError.new "Network Error: #{error}"
end
