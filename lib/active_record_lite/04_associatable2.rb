require_relative '03_associatable'

module Associatable

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]
  
    define_method(name) do
      source_options = 
          through_options.model_class.assoc_options[source_name]

      through_table = through_options.table_name
      through_pk = through_options.primary_key
      through_fk = through_options.foreign_key

      source_table = source_options.table_name
      source_pk = source_options.primary_key
      source_fk = source_options.foreign_key

      filter = self.send(through_fk)
      results = DBConnection.execute(<<-SQL, filter)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table}
        ON
          #{through_table}.#{source_fk} = #{source_table}.#{source_pk}
        WHERE
          #{through_table}.#{through_pk} = ?
      SQL

      source_options.model_class.parse_all(results).first
    end
  end
end
