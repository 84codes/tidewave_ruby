# frozen_string_literal: true

describe Tidewave::Tools::GetModels do
  describe "#call" do
    before do
      Tidewave.reset_config!
    end

    it "uses the adapter's get_models method and renders source locations" do
      account_model = double("Account", name: "Account")
      user_model = double("User", name: "User")

      adapter = instance_double(Tidewave::DatabaseAdapter)
      allow(adapter).to receive(:get_models).and_return([ account_model, user_model ])
      allow(Tidewave::DatabaseAdapter).to receive(:current).and_return(adapter)

      allow(Object).to receive(:const_source_location).with("Account").and_return([ "/app/models/account.rb", 1 ])
      allow(Object).to receive(:const_source_location).with("User").and_return([ "/app/models/user.rb", 1 ])

      result = described_class.new.call

      expect(result).to include("Account")
      expect(result).to include("User")
      expect(adapter).to have_received(:get_models)
    end

    it "handles models with missing source location" do
      empty = double("Empty", name: "EmptySourceModel")

      adapter = instance_double(Tidewave::DatabaseAdapter)
      allow(adapter).to receive(:get_models).and_return([ empty ])
      allow(Tidewave::DatabaseAdapter).to receive(:current).and_return(adapter)

      allow(Object).to receive(:const_source_location).with("EmptySourceModel").and_return(nil)

      result = described_class.new.call

      expect(result).to eq("* EmptySourceModel")
    end

    it "invokes the eager_load_callback when configured" do
      callback = double("callback")
      allow(callback).to receive(:respond_to?).with(:call).and_return(true)
      allow(callback).to receive(:call)

      Tidewave.config.eager_load_callback = callback

      adapter = instance_double(Tidewave::DatabaseAdapter)
      allow(adapter).to receive(:get_models).and_return([])
      allow(Tidewave::DatabaseAdapter).to receive(:current).and_return(adapter)

      described_class.new.call

      expect(callback).to have_received(:call)
    end
  end
end
