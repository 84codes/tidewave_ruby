# frozen_string_literal: true

module Tidewave
  module Tools
    class Base < FastMcp::Tool
      # Track descendants explicitly — Class#descendants does not exist in
      # core Ruby.
      @descendants = []

      class << self
        def descendants
          @descendants ||= []
        end

        def inherited(subclass)
          super
          Tidewave::Tools::Base.descendants << subclass
        end
      end
    end
  end
end
