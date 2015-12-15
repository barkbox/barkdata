module Barkdata

  class Registry

    def initialize
    end

    def self.register(class_name, &block)
      base_class = class_name.base_class
      table_name = class_name.table_name
      Rails.logger.info "Barkdata.register " +
                        "class=#{class_name.name.inspect} " +
                        "base_class=#{base_class.name.inspect} " +
                        "table_name=#{table_name.inspect}"
      Barkdata::Config.instance.registered_objects[base_class.name] = {
        table_name: table_name,
        base_class: base_class,
        ignored_columns: []
      }

      base_class.instance_eval do

        def ignore_column column_name
          Barkdata::Config.instance.registered_objects[self.base_class.name][:ignored_columns] << column_name
        end

        # Enables capturing of row level changes into barkdata_changecapture table.
        def enable_changecapture
          Barkdata::Changelog.enable(self)
        end

        # Enables capturing of row level changes into barkdata_changecapture table.
        def disable_changecapture
          Barkdata::Changelog.disable(self)
        end

        # Takes a full dump of all rows in a table into a flat file in /tmp.
        def full_snapshot
          Barkdata::Snapshot.full_snapshot(self)
        end

        def get_schema
          Barkdata::Schema.get(self)
        end

      end

      class_name.class_eval &block if block_given?
    end

    def self.status
      trigger_status = {}
      q = %Q{
        SELECT
          relname, tgname, tgrelid
        FROM
          pg_trigger
        LEFT JOIN pg_class ON
          pg_class.oid=tgrelid
        WHERE
          tgname='barkdata_change_capture_row';
      }
      results = ActiveRecord::Base.connection.execute(q)
      results.each do |res|
        trigger_status[res['relname']] = true
      end
      self.registered_objects.each do |registered_object|
        table_name = registered_object[:table_name]
        Rails.logger.info "Barkdata.status " +
                          "table_name=#{table_name.inspect} " +
                          "enabled=#{(trigger_status[table_name]||false).inspect}"
      end
    end

    def self.registry
      Barkdata::Config.instance.registered_objects
    end

    def self.registered_objects
      Barkdata::Config.instance.registered_objects.values
    end

  end

end
