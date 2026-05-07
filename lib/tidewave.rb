# frozen_string_literal: true

require "tidewave/version"
require "tidewave/configuration"

module Tidewave
  module DatabaseAdapters
    # This module is defined here to ensure it's available for autoloading.
    # Individual adapters are loaded on-demand in database_adapter.rb.
  end

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
      config
    end

    def reset_config!
      @config = Configuration.new
    end
  end
end

require "tidewave/database_adapter"
