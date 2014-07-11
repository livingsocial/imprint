require 'imprint/version'
require 'imprint/middleware'
require 'imprint/tracer'

module Imprint

  FULL_PARAMS = :full
  QUERY_PARAMS = :query
  FULL_GET_PARAMS = :full_get

  class << self
    attr_accessor :configuration
  end

  def self.configure(configs = {})
    self.configuration ||= {}
    self.configuration = configuration.merge(configs)
  end

end
