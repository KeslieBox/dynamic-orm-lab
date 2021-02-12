require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{self.table_name}')"
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each do |row|
      column_names << row["name"]
    end
    column_names.compact
  end

  def initialize(options={})
    options.each do |attribute, value|
      self.send("#{attribute}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|column_name| column_name == "id"}.join(", ")
  end

  def values_for_insert 
    values = []
    self.class.column_names.each do |column_name|
      # #send allows you to "send" or call a method when you won't know the name of that method until runtime
      values << "'#{send(column_name)}'" unless send(column_name).nil?
    end
    values.join(", ")
  end

  def save
    # why does #{values_for_insert} need to be inside ()?
    sql = "INSERT INTO #{table_name_for_insert}(#{col_names_for_insert}) VALUES (#{values_for_insert})" 
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute)
    # how to account for when attribute is an integer 
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute.keys.join()} = ?"
    DB[:conn].execute(sql, "#{attribute.values.join()}")
  end

end