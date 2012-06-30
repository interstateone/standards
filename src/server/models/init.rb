# Get ILIKE support (case-insensitive like) for Postgres
module DataMapper
  module Adapters

    class PostgresAdapter < DataObjectsAdapter

      module SQL #:nodoc:
        private

        # @api private
        def supports_returning?
          true
        end

        def like_operator(operand)
          'ILIKE'
        end
      end

      include SQL

    end

    const_added(:PostgresAdapter)

  end
end

require_relative 'user'
require_relative 'task'
require_relative 'check'

DataMapper.finalize.auto_upgrade!