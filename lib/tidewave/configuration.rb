# frozen_string_literal: true

require "pathname"
require "logger"

module Tidewave
  class Configuration
    attr_accessor :logger, :allow_remote_access, :preferred_orm, :dev,
                  :client_url, :team, :logger_middleware,
                  :application_name, :environment,
                  :eager_load_callback, :log_path

    attr_reader :root

    def initialize
      @logger = nil
      @allow_remote_access = true
      @preferred_orm = :sequel
      @dev = false
      @client_url = "https://tidewave.ai"
      @team = {}
      @logger_middleware = nil
      @root = Pathname.new(Dir.pwd)
      @application_name = "Tidewave"
      @environment = ENV["RACK_ENV"] || "development"
      @eager_load_callback = nil
      @log_path = nil
    end

    def root=(path)
      @root = path.is_a?(Pathname) ? path : Pathname.new(path.to_s)
    end

    def resolved_log_path
      return @log_path if @log_path

      root.join("log", "#{environment}.log")
    end

    def resolved_logger
      @logger ||= Logger.new($stdout)
    end
  end
end
