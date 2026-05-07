# frozen_string_literal: true

module Tidewave
  module DatabaseAdapters
    class Sequel < DatabaseAdapter
      RESULT_LIMIT = 50

      def execute_query(query, arguments = [])
        db = ::Sequel::Model.db

        # Execute the query with arguments
        result = if arguments.any?
          db.fetch(query, *arguments)
        else
          db.fetch(query)
        end

        # Convert to array of hashes and extract metadata
        rows = result.all
        columns = rows.first&.keys || []

        {
          columns: columns.map(&:to_s),
          rows: rows.first(RESULT_LIMIT).map(&:values),
          row_count: rows.length,
          adapter: db.adapter_scheme.to_s.upcase,
          database: db.opts[:database]
        }
      end

      def get_models
        all_descendants(::Sequel::Model).reject do |model|
          model.name.nil? || model.name.start_with?("Sequel::_Model(")
        end
      end

      private

      def all_descendants(klass)
        result = []
        stack = klass.respond_to?(:subclasses) ? klass.subclasses.dup : []
        until stack.empty?
          current = stack.pop
          next if result.include?(current)

          result << current
          stack.concat(current.subclasses) if current.respond_to?(:subclasses)
        end
        result
      end
    end
  end
end
