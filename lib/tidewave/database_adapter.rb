# frozen_string_literal: true

module Tidewave
  class DatabaseAdapter
    class << self
      def current
        @current ||= create_adapter
      end

      def reset!
        @current = nil
      end

      def create_adapter
        orm_type = Tidewave.config.preferred_orm
        case orm_type
        when :sequel
          require_relative "database_adapters/sequel"
          DatabaseAdapters::Sequel.new
        else
          raise "Unknown preferred ORM: #{orm_type}"
        end
      end
    end

    def execute_query(query, arguments = [])
      raise NotImplementedError, "Subclasses must implement execute_query"
    end

    def get_models
      raise NotImplementedError, "Subclasses must implement get_models"
    end
  end
end
