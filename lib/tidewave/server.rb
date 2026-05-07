# frozen_string_literal: true

require "tidewave"
require "tidewave/middleware"
require "rack"

module Tidewave
  # Embedded HTTP server for non-web Ruby processes (background workers,
  # queue consumers, daemons). It boots a small Rack handler bound to the
  # loopback interface that exposes the same /tidewave endpoints as the
  # middleware would in a web app, while sharing the host process's Ruby
  # VM, database connections, in-memory state and loggers.
  #
  # Typical usage from a worker:
  #
  #     require "tidewave/server"
  #
  #     Tidewave.configure do |c|
  #       c.application_name    = "MyWorker"
  #       c.preferred_orm       = :sequel
  #       c.root                = Pathname.new(__dir__)
  #       c.allow_remote_access = false
  #     end
  #
  #     Tidewave::Server.start(port: 9395) if ENV["RACK_ENV"] == "development"
  #
  # Returns the background Thread (when `background: true`, the default) so
  # callers can join or kill it.
  module Server
    DEFAULT_HOST = "127.0.0.1"
    DEFAULT_PORT = 9395

    NOT_FOUND_APP = lambda do |_env|
      [
        404,
        { "Content-Type" => "text/plain" },
        [ "Tidewave standalone server. The MCP endpoint lives at /tidewave/mcp.\n" ]
      ]
    end

    class << self
      # Boot the embedded server.
      #
      # @param host [String] interface to bind to (defaults to 127.0.0.1).
      # @param port [Integer] TCP port (defaults to 9395).
      # @param app  [#call]   inner Rack app to forward non-/tidewave requests
      #                       to. Defaults to a 404 responder.
      # @param handler [#run] Rack handler. Defaults to whatever
      #                       Rackup::Handler / Rack::Handler picks up first
      #                       (typically puma if it's in your Gemfile).
      # @param background [Boolean] run the handler in a Thread (default) or
      #                       block on the current thread.
      # @return [Thread, nil] the background Thread, or nil when blocking.
      def start(host: DEFAULT_HOST, port: DEFAULT_PORT, app: nil, handler: nil, background: true)
        rack_handler = handler || resolve_handler
        rack_app = build_app(app)
        runner = -> { rack_handler.run(rack_app, Host: host, Port: port, Silent: true) }

        if background
          Thread.new do
            Thread.current.name = "tidewave-server"
            runner.call
          end
        else
          runner.call
          nil
        end
      end

      private

      def build_app(inner_app)
        inner = inner_app || NOT_FOUND_APP
        Rack::Builder.app do
          use Tidewave::Middleware
          run inner
        end
      end

      # Return a Rack handler usable with Rack 2 (`Rack::Handler`) or Rack 3
      # (where the handler interface lives in the separate `rackup` gem).
      def resolve_handler
        if defined?(::Rackup::Handler) || try_require("rackup")
          ::Rackup::Handler.default
        elsif defined?(::Rack::Handler) && ::Rack::Handler.respond_to?(:default)
          ::Rack::Handler.default
        else
          raise "Tidewave::Server could not find a Rack handler. Add `gem \"puma\"` (or another Rack handler) to your Gemfile, or pass `handler:` explicitly."
        end
      end

      def try_require(lib)
        require lib
        true
      rescue LoadError
        false
      end
    end
  end
end
