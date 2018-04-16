require 'sqlite3'

module Selection
	def find_one(id)
		if id.is_a?(Integer) && id > 0
			row = connection.get_first_row <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				WHERE id = #{id};
			SQL

			init_object_from_row(row)
		else
			puts "Not a valid ID. Please try again"
			return -1
		end
	end

	def find(*ids)
		if ids.length == 1 && ids.first.is_a?(Integer)
			find_one(ids.first)
		end
		if ids.length > 1
			ids.each do |id| 
				if !id.is_a?(Integer)
					puts "invalid combination of ids"
					return -1
				end
			end
		else
			rows = connection.execute <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				WHERE id IN (#{ids.join(",")});
			SQL

			rows_to_array(rows)
		end
	end

	def find_by(attribute, value)
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{attribute} = #{BlocRecord::Utility.sql_strings(value)};
		SQL
		init_object_from_row(row)
	end

	def take_one
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY random()
			LIMIT 1;
		SQL
	end

	def take(num=1)
		if num > 1 
			rows = connection.execute <<-SQL 
				SELECT #{columns.join ","} FROM #{table}
				ORDER BY random()
				LIMIT #{num};
			SQL
			rows_to_array(rows)
		else 
			take_one
		end
	end

	#get first and last records
	def first
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY id ASC LIMIT 1;
		SQL
		init_object_from_row(row)
	end

	def last 
		row = connection.get_first_row <<-SQL
			SELECT #{columns.join ","} FROM #{table}
			ORDER BY id DESC LIMIT 1;
		SQL
		init_object_from_row(row)
	end

	#get all recors

	def all
		rows = connection.execute <<-SQL 
			SELECT #{columns.join ","} FROM #{table};
		SQL
		rows_to_array(rows)
	end

	def where(*args)
		if args.count > 1
			expression = args.shift
			params = args
		else 
			case args.first 
				when String 
					expression = args.first 
				when Hash 
					expression_hash = BlocRecord::Utility.convert_keys(args.first)
					expression = expression_hash.map {|key, value| "#{key}=#{BlocRecord::Utility.sql_strings(value)}"}.join(" and ")
			end
		end

		sql = <<-SQL 
			SELECT #{columns.join ","} FROM #{table}
			WHERE #{expression};
		SQL

		rows = connection.execute(sql, params)
		rows_to_array(rows)
	end

	def order(*order) 
		if args.count. > 1 
			order = args.join(",")
		else
			order = args.first.to_s
		end

		rows = connection.execute <<-SQL
			SELECT * FROM #{table}
			ORDER BY #{order};
		SQL
		rows_to_array(rows)
	end

	def join(*args)
		if args.count > 1
			joins = args.map { |arg| "INNER JOIN #{arg} ON #{arg}.#{table}_id = #{table}.id"}.join(" ")
			rows = connection.execute <<-SQL 
				SELECT * FROM #{table} #{joins};
			SQL
		else
			case args.first
				when String
					rows = connection.execute <<-SQL
						SELECT * FROM #{table} #{BlocRecord::Utility.sql_strings(args.first)};
					SQL
				when Symbol
					rows = connection.execute <<-SQL 
					SELECT * FROM #{table}
					INNER JOIN #{args.first} ON #{arg.first}.#{table}_id = #{table}.id
					SQL
			 end 
		end
		rows_to_array(rows)
	end



	#support for batches
	def find_each(options={})
		start = options[:start]
		batch_size = options[:batch_size]
		# check options for start and batch_size values
		if start != nil && batch_size != nil
			rows = connection.execute <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				LIMIT #{batch_size} OFFSET #{start};
			SQL
		elsif start != nil && batch_size == nil
			rows = connection.execute <<-SQL 
				SELECT #{columns.join ","} FROM #{table}
				OFFSET #{start};
			SQL
		elsif start == nil && batch_size != nil 
			rows = connection.execute <<-SQL 
				SELECT #{columns.join ","} FROM #{table}
				LIMIT #{batch_size};
			SQL
		else 
			rows = connection.execute <<-SQL 
				SELECT #{columns.join ","} FROM #{table};
			SQL
		end

		rows.each do |row| 
			yield init_object_from_row(row)
		end
	end

	#similar to #find_each but yields an an array instead. maybe there's a better way to shorten this through altering #method_missing
	def find_in_batches(options={})
		start = options[:start]
		batch_size = options[:batch_size]
		# check options for start and batch_size values
		if start != nil && batch_size != nil
			rows = connection.execute <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				LIMIT #{batch_size} OFFSET #{start};
			SQL
		elsif start != nil && batch_size == nil
			rows = connection.execute <<-SQL
				SELECT #{columns.join ","} FROM #{table}
				OFFSET #{start};
			SQL
		elsif start == nil && batch_size != nil 
			rows = connection.execute <<-SQL 
				SELECT #{columns.join ","} FROM #{table}
				LIMIT #{batch_size};
			SQL
		else 
			rows = connection.execute <<-SQL 
				SELECT #{columns.join ","} FROM #{table};
			SQL
		end

		row_array = rows_to_array(rows)
		yield(row_array)

	end





	#method missing overwrite
	def method_missing(method_missing, *args)
		if method_name.match(/find_by_/)
			attribute = method_name.split('find_by_')[1]
			if columns.include?(attribute)
				find_by(attribute, *args)
			else
				puts "The #{attribute} does not exist in the current database"
			end
		else 
			puts "Not a valid method"
			return -1
		end
	end
	

	private
		def rows_to_array(rows)
			rows.map { |row| new(Hash[columns.zip(row)]) }
		end

		def init_object_from_row(row)
			if row
				data = Hash[columns.zip(row)]
				new(data)
			end
		end
end
