require 'sqlite3'
require 'active_support/inflector'

module Associations

    def has_many(association)
        define_method(association) do 
            rows = self.class.connection.execute <<-SQL
                SELECT * FROM #{association.to_s.singularize}
                WHERE #{self.class.table}_id = #{self.id};
            SQL

            #create a new class name e.g entries becomes Entry
            #create a new collection
            class_name = association.to_s.classify.constantize
            collection = BlocRecord::Collection.new

            #go through rows and build a collection of relevant objects
            rows.each do |row|
                collection << class_name.new(Hash[class_name.columns.zip(row)])
            end

            #return the collection as an array of Hash objects
            collection
        end
    end

    def belongs_to(association)
        define_method(association) do 
            association_name = association.to_s
            row = self.class.connection.get_first_row <<-SQL
                SELECT * FROM #{association_name}
                WHERE id = #{self.send(association_name + "_id")};
            SQL

            class_name = association_name.classify.constantize

            if row 
                data = Hash[class_name.columns.zip(row)]
                class_name.new(data)
            end
        end
    end
end