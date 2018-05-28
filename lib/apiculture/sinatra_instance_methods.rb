require 'json'

# Some sugary methods for use within Sinatra, when responding to a request/rendering JSON
module Apiculture::SinatraInstanceMethods
  NEWLINE = "\n"
  DEFAULT = :__default__
  
  # Convert the given structure to JSON, set the content-type and
  # return the JSON string
  def json_response(structure, status: DEFAULT)
    content_type :json
    status(status) unless status == DEFAULT
    JSON.pretty_generate(structure)
  end
  
  # Bail out from an action by sending a halt() via Sinatra. Is most useful for
  # handling access denied, invalid resource and other types of situations
  # where you don't want the request to continue, but still would like to
  # provide a decent error message to the client that it can parse
  # with it's own JSON means.
  def json_halt(with_error_message, status: 400, **attrs_for_json_response)
    # Pretty-print + newline to be terminal-friendly
    err_str = JSON.pretty_generate({error: with_error_message}.merge(attrs_for_json_response)) + NEWLINE
    halt status, {'Content-Type' => 'application/json'}, [err_str]
  end
  
  # Handles the given action via the given class, passing it the instance variables
  # given in the keyword arguments
  def action_result(action_class, **action_ivars)
    call_result = action_class.new(self, **action_ivars).perform
    unless call_result.is_a?(Array) || call_result.is_a?(Hash) || (call_result.nil? && @status == 204)
      raise "Action result should be an Array, a Hash or it can be nil but only if status is 204, instead it was a #{call_result.class}"
    end
  
    json_response call_result if call_result
  end
end
