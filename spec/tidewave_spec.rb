# frozen_string_literal: true

RSpec.describe Tidewave do
  it "has a version number" do
    expect(Tidewave::VERSION).not_to be nil
  end

  it "exposes a Configuration instance via .config" do
    expect(Tidewave.config).to be_a(Tidewave::Configuration)
  end
end
