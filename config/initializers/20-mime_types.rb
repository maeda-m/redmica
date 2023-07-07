# frozen_string_literal: true

# Add new mime types for use in respond_to blocks:
Mime::Type.register('application/json', :api, %w(application/xml))

# See: https://github.com/rails/rails/blob/7-0-stable/actionpack/lib/action_dispatch/http/parameters.rb#L10-L15
original_parsers = ActionDispatch::Request.parameter_parsers
ActionDispatch::Request.parameter_parsers = original_parsers.merge({
  Mime[:api].symbol => ActionDispatch::APIParameterParser
})
