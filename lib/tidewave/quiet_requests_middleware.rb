# frozen_string_literal: true

class Tidewave::QuietRequestsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  end
end
