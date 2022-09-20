require 'json'
require 'dotenv'
# Add your gem requires here:
# require 'some_gem'
require_relative './space_stone/env'
# Add your additional lib PORO requires here:
# require_relative './space_stone/some_poro

def handler(event:, context:)
  puts event
  { statusCode: 200,
    headers: [{'Content-Type' => 'application/json'}],
    body: JSON.dump(event) }
end
