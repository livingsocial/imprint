require 'imprint/version'
require 'imprint/middleware'
require 'imprint/tracer'

module Imprint

  class << self
    attr_accessor :configuration
  end

  def self.configure(configs = {})
    self.configuration ||= {}
    self.configuration = configuration.merge(configs)
  end

end
