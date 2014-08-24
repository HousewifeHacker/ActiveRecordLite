require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
   
    query = DBConnection.execute2("SELECT * FROM #{table_name}")
    query.first.map!(&:to_sym)
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end
      define_method(col) do
        self.attributes[col]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    db = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL

    parse_all(db)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    db = DBConnection.execute(<<-SQL, id)
    SELECT
      #{ table_name }.*
    FROM
      #{ table_name }
    WHERE
      #{ table_name }.id = ?
    SQL

    parse_all(db).first
  end

  def attributes
    @attributes ||= {}        
  end

  def insert
    columns = self.class.columns
    
    col_names = columns.join(', ')
    question_marks = (['?'] * columns.count).join(', ')
    DBConnection.execute(<<-SQL, attribute_values)
    INSERT INTO
      #{ self.class.table_name } (#{ col_names })
    VALUES
      (#{ question_marks })
    SQL
    
    new_id = DBConnection.last_insert_row_id
    self.send(:id=, new_id)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      sym_name = attr_name.to_sym
      unless self.class.columns.include?(sym_name)
        raise "unknown attribute '#{ sym_name }'"
      end
      send("#{ sym_name }=", value)
    end
  end

  def save
    id.nil? ? insert : update
  end

  def update
    set_row = self.class.columns
              .map{ |col_name| "#{ col_name } = ?" }.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE 
        #{ self.class.table_name }
      SET
        #{ set_row }
      WHERE
        #{ self.class.table_name }.id = ?
     SQL
  end

  def attribute_values
    self.class.columns.map{ |col| send(col) }    
  end
end
