# An Action is like a Sinatra route method wrapped in a class.
# It gets instantiated with a number of instance variables (via keyword arguments)
# and the Sinatra application calling the action.
#
# All the methods available within Sinatra are also available within the Action,
# via method delegation (this primarily concerns methods like +request+, +env+, +params+
# and so forth).
#
# The main work method is +perform+ which should return a data structure that can be converted
# into JSON by the caller.
class Apiculture::Action
  # Initialize a new BasicAction, with the given Sintra application and a hash
  # of keyword arguments that will be converted into instance variables.
  def initialize(app_receiver, **ivars)
    ivars.each_pair {|k,v| instance_variable_set("@#{k}", v) }
    @_sinatra_app = app_receiver
  end
  
  # Halt with a JSON error message (delegates to Sinatra's halt() under the hood)
  def bail(with_error_message, status: 400, **attrs_for_json_response)
    @_sinatra_app.json_halt(with_error_message, status: status, **attrs_for_json_response)
  end
  
  # Respond to all the methods the contained Sinatra app supports
  def respond_to_missing?(*a)
    super || @_sinatra_app.respond_to?(*a)
  end
  
  # Respond to all the methods the contained Sinatra app supports
  def method_missing(m, *a, &b)
    if @_sinatra_app.respond_to?(m)
      @_sinatra_app.public_send(m, *a, &b)
    else
      super
    end
  end
  
  # Performs the action and returns it's result.
  #
  # If the action result is an Array or a Hash, it will be converted into JSON
  # and output.
  #
  # If something else is returned an error will be raised.
  def perform
  end
end
