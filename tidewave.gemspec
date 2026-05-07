# frozen_string_literal: true

require_relative "lib/tidewave/version"

Gem::Specification.new do |spec|
  spec.name        = "tidewave"
  spec.version     = Tidewave::VERSION
  spec.authors     = [ "Yorick Jacquin", "José Valim" ]
  spec.email       = [ "support@tidewave.ai" ]
  spec.homepage    = "https://tidewave.ai/"
  spec.summary     = "Tidewave for Ruby (Sinatra, Rack, and standalone Ruby apps)"
  spec.description = "Tidewave: a Model Context Protocol server and Rack middleware that lets coding agents introspect and act on Ruby applications. Works with Sinatra, any Rack-based stack, and standalone Ruby processes."
  spec.license     = "Apache-2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tidewave-ai/tidewave_ruby"
  spec.metadata["changelog_uri"] = "https://github.com/tidewave-ai/tidewave_ruby/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE", "README.md"]
  end

  spec.add_dependency "fast-mcp", "~> 1.6.0"
  spec.add_dependency "rack", ">= 2.0"
end
