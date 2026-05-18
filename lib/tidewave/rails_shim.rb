# frozen_string_literal: true

# Minimal Rails-API stub for the tidewave.ai frontend and the Tidewave
# connectivity probe, which evaluate things like `Rails.env` or
# `Rails.application.config.something` to confirm the app is alive.
#
# This is NOT Rails. It answers just enough of the surface so probes
# don't raise NameError when running under Sinatra, plain Rack, workers,
# or standalone scripts.
#
# Auto-installed by Tidewave::Middleware (and Tidewave::Server) when no
# real Rails constant is defined. Hosts that already have Rails get the
# real one and skip this entirely.
module Tidewave
  module RailsShim
    # String-like that responds to development?/test?/production? etc.,
    # matching ActiveSupport::StringInquirer behavior closely enough for
    # the frontend's environment checks.
    class StringInquirer < String
      def method_missing(name, *args)
        name = name.to_s
        return self == name.chomp("?") if name.end_with?("?")

        super
      end

      def respond_to_missing?(name, include_private = false)
        name.to_s.end_with?("?") || super
      end
    end

    # Returns itself for any method call so chained probes like
    # Rails.application.config.something resolve harmlessly to an
    # inspectable sentinel rather than raising NoMethodError.
    class DeepStub
      def method_missing(_name, *_args, &_blk) = self
      def respond_to_missing?(_name, _ = false) = true
      def to_s = ""
      def inspect = "#<Rails (Tidewave shim)>"
    end

    # The faux Rails module installed at the top level. Mirrors the
    # handful of methods the tidewave.ai frontend touches.
    module FakeRails
      module_function

      def env
        @env ||= StringInquirer.new(
          Tidewave.config.environment || ENV.fetch("RACK_ENV", "development")
        )
      end

      def root
        @root ||= Tidewave.config.root || Pathname.new(Dir.pwd)
      end

      def logger
        @logger ||= Tidewave.config.resolved_logger if Tidewave.config.respond_to?(:resolved_logger)
        @logger ||= Logger.new($stdout)
      end

      def application
        @application ||= DeepStub.new
      end

      def version = "0.0.0-tidewave-shim"
    end

    # Define ::Rails as the FakeRails module if no real Rails is loaded.
    # Idempotent: a second call (e.g., after a real Rails appears later)
    # is a no-op.
    def self.install!
      return if defined?(::Rails)

      require "logger"
      require "pathname"
      Object.const_set(:Rails, FakeRails)
    end
  end
end
