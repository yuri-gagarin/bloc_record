require 'sqlite3'
require 'bloc_record/utility'

module Schema
	def table
		BlocRecord::Utility.underscore(name)
	end

	def schema
		unless @schema
			@schema = {}
			connection.table_info(table) do |column|
				@schema[column["name"]] = column["type"]
			end
		end
		@schema
	end

	def columns
		schema.keys
	end

	def attributes
		columns - ["id"]
	end

	def count
		connection.execute(<<-SQL)[0][0]
			SELECT COUNT(*) FROM #{table}
		SQL
	end
end