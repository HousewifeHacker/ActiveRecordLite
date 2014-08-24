require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = { class_name: name.to_s.camelcase,
                 foreign_key: "#{name}_id".to_sym,
                 primary_key: :id
    }
    defaults.merge!(options)
    defaults.each{ |k, v| send("#{k}=", v) }
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    # has_many have plural association names
     defaults = { class_name: name.to_s.singularize.camelcase,
                 foreign_key: "#{self_class_name.underscore}_id".to_sym,
                 primary_key: :id
    }
    defaults.merge!(options)
    defaults.each{ |k, v| self.send("#{k}=", v) }
  end
end

module Associatable
  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name, options)
    define_method(name) do
      obj = self.class.assoc_options[name]
      fk = self.send(obj.foreign_key)
      obj.model_class.where(obj.primary_key => fk).first
    end
  end

  def has_many(name, options = {})
    assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      obj = self.class.assoc_options[name]
      pk = self.send(obj.primary_key)
      obj.model_class.where(obj.foreign_key => pk)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
