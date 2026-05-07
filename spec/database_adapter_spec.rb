# frozen_string_literal: true

describe Tidewave::DatabaseAdapter do
  before do
    described_class.reset!
    Tidewave.reset_config!
  end

  describe ".current" do
    it "returns the same adapter instance on subsequent calls" do
      Tidewave.config.preferred_orm = :sequel
      adapter1 = described_class.current
      adapter2 = described_class.current
      expect(adapter1).to be(adapter2)
    end
  end

  describe ".create_adapter" do
    context "when preferred_orm is :sequel" do
      it "returns a Sequel adapter" do
        Tidewave.config.preferred_orm = :sequel
        adapter = described_class.create_adapter
        expect(adapter).to be_a(Tidewave::DatabaseAdapters::Sequel)
      end
    end

    context "when preferred_orm is unknown" do
      it "raises an error" do
        Tidewave.config.preferred_orm = :unknown
        expect { described_class.create_adapter }.to raise_error("Unknown preferred ORM: unknown")
      end
    end
  end
end
