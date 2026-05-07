# Tidewave (Ruby, non-Rails)

Tidewave is an MCP (Model Context Protocol) server that lets coding agents
(Claude Code, OpenAI Codex, Cursor, etc.) introspect and act on a running
Ruby application: query the database, evaluate code in the live VM, list
models, read logs, look up source locations.

> **Using Rails?** This fork targets non-Rails Ruby apps. Use the official
> [`tidewave-ai/tidewave_rails`](https://github.com/tidewave-ai/tidewave_rails)
> gem instead — it ships a Railtie and is the supported path for Rails.

This gem covers everything else:

- **Sinatra / plain Rack apps** — `use Tidewave::Middleware` in your Rack stack.
- **Background workers, queue consumers, daemons, plain Ruby scripts** —
  call `Tidewave::Server.start` to boot a small in-process HTTP server
  bound to loopback. No existing Rack app required.

Because the MCP server runs **inside your process**, agents share your
Ruby VM, database connections, in-memory state, and loggers.

## With or without a tidewave.ai subscription

You can use this gem two ways:

### Connect Claude Code to MCP endpoint (no subscription needed)

Point any MCP-capable client at `http://127.0.0.1:<port>/tidewave/mcp` and you get the full
tool list below — SQL queries, `project_eval`, `get_logs`, `get_models`,
`get_source_location`, `get_docs`. This is the typical setup for Claude
Code / Codex / Cursor users who already have their own agent and just
want it to reach into the app. Nothing leaves your machine.

For Claude Code (or any MCP client that reads `.mcp.json`), add an HTTP
entry per process. If your app exposes the web stack on one port and a
worker via `Tidewave::Server` on another, list both — agents can pick
which one to talk to:

```json
{
  "mcpServers": {
    "web-tidewave": {
      "type": "http",
      "url": "http://localhost:9393/tidewave/mcp"
    },
    "worker-tidewave": {
      "type": "http",
      "url": "http://localhost:9395/tidewave/mcp"
    }
  }
}
```

Or from the CLI:

```shell
claude mcp add --transport http web-tidewave http://localhost:9393/tidewave/mcp
claude mcp add --transport http worker-tidewave http://localhost:9395/tidewave/mcp
```

### Connect Tidewave app or CLI to MCP

For the complete Tidewave experience, install the Desktop or CLI app from
[tidewave.ai](https://tidewave.ai), authenticate with GitHub, and sign
up for the Pro plan. The app connects to your locally running server
and adds a coding workspace on top of the same MCP tools: chat, in-page
editing, contextual browser testing, and team features. See
<https://hexdocs.pm/tidewave> for the full feature list.

## Installation

This fork is not published to RubyGems — install it directly from GitHub
in your `Gemfile`:

```ruby
git "https://github.com/84codes/tidewave_ruby.git", branch: "main" do
  gem "tidewave", group: :development
end
```

Then `bundle install`.

## Sinatra / plain Rack

Configure Tidewave once and add the middleware at the top of your Rack
stack. **Only enable it in development** — Tidewave can run arbitrary
Ruby and shell commands.

```ruby
if ENV["RACK_ENV"] == "development"
  require "tidewave"
  require "tidewave/middleware"

  Tidewave.configure do |c|
    c.application_name    = "MyApp"
    c.preferred_orm       = :sequel        # only adapter shipped
    c.root                = Pathname.new(__dir__)
    c.environment         = "development"
    c.log_path            = Pathname.new(__dir__).join("log/web-development.log")
    c.allow_remote_access = false          # loopback only
  end
end

class WebApp
  def initialize
    @app = Rack::Builder.new do
      use Tidewave::Middleware if ENV["RACK_ENV"] == "development" && defined?(Tidewave)
      # ... rest of your Rack stack
    end
  end
end
```

The MCP endpoint is mounted at `/tidewave/mcp` on whatever host/port your
Rack server already listens on.

## Background workers, daemons, plain scripts (no HTTP server)

For non-web processes, `Tidewave::Server.start` boots an embedded Rack
handler bound to loopback in a background thread, sharing the host
process's VM, DB connections, and loggers:

```ruby
if ENV["RACK_ENV"] == "development"
  require "tidewave"
  require "tidewave/server"
  require "rack/handler/puma"

  Tidewave.configure do |c|
    c.application_name    = "MyWorker"
    c.preferred_orm       = :sequel
    c.root                = Pathname.new(__dir__)
    c.log_path            = Pathname.new(__dir__).join("log/worker-development.log")
    c.allow_remote_access = false
  end

  Tidewave::Server.start(
    port: Integer(ENV.fetch("TIDEWAVE_PORT", 9395)),
    handler: Rack::Handler::Puma
  )
end
```

`Tidewave::Server.start` options:

- `host:` — interface to bind to (default `127.0.0.1`).
- `port:` — TCP port (default `9395`).
- `handler:` — Rack handler. Defaults to `Rackup::Handler.default` /
  `Rack::Handler.default` (typically Puma if it's in your Gemfile).
- `app:` — inner Rack app for non-`/tidewave` requests. Defaults to a
  404 responder.
- `background:` — run in a Thread (default) or block on the current
  thread.

If you run multiple workers on the same host, give each one a distinct
`TIDEWAVE_PORT`.

## Configuration

`Tidewave.configure` exposes the following on `Tidewave::Configuration`:

| Option                 | Default                                  | Purpose                                                                                                  |
| ---------------------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `application_name`     | `"Tidewave"`                             | Project name advertised to the MCP client / tidewave.ai UI.                                              |
| `preferred_orm`        | `:sequel`                                | Picks the database adapter used by `execute_sql_query` / `get_models`. Sequel is the only adapter shipped. |
| `root`                 | `Pathname.new(Dir.pwd)`                  | Project root. Used by `get_source_location` and to derive default log paths. Coerced to `Pathname`.      |
| `environment`          | `ENV["RACK_ENV"] \|\| "development"`     | Used by `resolved_log_path` and reported to the MCP client. Safe to leave at the default.                |
| `log_path`             | `nil`                                    | File path that `get_logs` reads. Falls back to `<root>/log/<environment>.log` when unset.                |
| `eager_load_callback`  | `nil`                                    | Callable invoked before `get_models` enumerates models. Only needed if your app lazy-loads model files.  |
| `allow_remote_access`  | `false`                                  | If `false`, Tidewave rejects non-loopback connections regardless of what interface your server binds to. See <https://hexdocs.pm/tidewave/security.html>. |
| `client_url`           | `https://tidewave.ai`                    | Allowed `Origin` for browser connections from the tidewave.ai frontend.                                  |
| `team`                 | `{}`                                     | tidewave.ai team config, e.g. `{ id: "my-company" }`. Only relevant with a subscription.                 |
| `logger`               | `Logger.new($stdout)` (lazy)             | Logger used by the middleware / server.                                                                  |
| `logger_middleware`    | `nil`                                    | Optional middleware whose logs Tidewave silences for its own requests.                                   |
| `dev`                  | `false`                                  | Internal flag used by tidewave maintainers.                                                              |

`Tidewave.reset_config!` wipes the global config (useful in tests).

## Available tools

- `execute_sql_query` — execute a SQL query against your application's
  database via Sequel.
- `get_docs` — fetch documentation for a module / class / method, using
  the exact versions your project depends on.
- `get_logs` — tail the file at `config.log_path` (or
  `<root>/log/<environment>.log`).
- `get_models` — list all models and where they're defined. The gem
  walks `Sequel::Model`'s subclass tree directly.
- `get_source_location` — return the file/line for a module / class /
  method so the agent can read source directly.
- `project_eval` — evaluate Ruby in your process, with access to
  runtime, dependencies, and in-memory state.

## Security notes

- Tidewave can run arbitrary Ruby and shell. Never enable it in
  production. Gate the `require` and `Tidewave.configure` behind
  `RACK_ENV == "development"`.
- `allow_remote_access: false` (the default) restricts MCP traffic to
  127.0.0.1 regardless of what your Rack server binds to.
- If you enable `client_url` / browser access, Tidewave enables
  `script-src 'unsafe-eval'` and disables `frame-ancestors` in its
  responses so contextual browser testing works.

## Troubleshooting

### Multiple hosts/subdomains during development

If you serve development traffic across subdomains, use `*.localhost` —
browsers treat those as secure contexts. With `rack-session` ≥ 2.1 you
can configure cookies as:

```ruby
use Rack::Session::Cookie,
  key: "__your_app_session",
  same_site: :none,
  secure: true
```

This lets the tidewave.ai frontend embed your app across subdomains.
