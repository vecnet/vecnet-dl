if Rails::VERSION::MAJOR < 4
  #Fix fixtures with foreign keys, fixed in Rails4
  class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    def disable_referential_integrity #:nodoc:
      begin
        if supports_disable_referential_integrity? then
          execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} DISABLE TRIGGER USER" }.join(";"))
        end
        #Having trouble in rake rspec on schema load on these two table.. need to rescue them since I could not find solution to fix it
        #execute(['conversations','notifications'].collect { |name| "DROP TABLE #{quote_table_name(name)} CASCADE" }.join(";"))
        yield
      ensure
        if supports_disable_referential_integrity? then
          execute(tables.collect { |name| "ALTER TABLE #{quote_table_name(name)} ENABLE TRIGGER USER" }.join(";"))
        end
      end
    end
  end
end