module Barkdata

  class Changelog

    def initialize
    end

    def self.enable model
      unless Barkdata.enabled?
        Rails.logger.info "Barkdata.register SKIP if ENABLE_BARKDATA_CHANGECAPTURE is not set to true."
        return
      end
      Rails.logger.info "Barkdata::Changelog.enable: #{model.table_name}"
      q = %Q{
        DROP TRIGGER IF EXISTS barkdata_change_capture_row ON #{model.table_name};
        CREATE TRIGGER barkdata_change_capture_row AFTER INSERT OR UPDATE OR DELETE ON #{model.table_name} FOR EACH ROW EXECUTE PROCEDURE barkdata.if_modified_func();
        DROP TRIGGER IF EXISTS barkdata_change_capture_stm ON #{model.table_name};
        CREATE TRIGGER barkdata_change_capture_stm AFTER TRUNCATE ON #{model.table_name} FOR EACH STATEMENT EXECUTE PROCEDURE barkdata.if_modified_func();
      }
      ActiveRecord::Base.connection.execute(q)
    end

    def self.disable model
      Rails.logger.info "Barkdata::Changelog.disable: #{model.table_name}"
      q = %Q{
        DROP TRIGGER IF EXISTS barkdata_change_capture_row ON #{model.table_name};
        DROP TRIGGER IF EXISTS barkdata_change_capture_stm ON #{model.table_name};
      }
      ActiveRecord::Base.connection.execute(q)
    end

    def self.enable_all
      Barkdata::Registry.registered_objects.each do |registered_object|
        registered_object[:base_class].enable_changecapture
      end
    end

    def self.disable_all
      Barkdata::Registry.registered_objects.each do |registered_object|
        registered_object[:base_class].disable_changecapture
      end
    end

    def self.archive_to_s3
      @project_name = Barkdata::Config.instance.project_name
      latest_change_id = self.get_latest_change_id
      time_prefix = Time.now.utc.strftime("%Y-%m-%d-%H-%M-%S")
      tmp_filepath = "/tmp/barkdata-changelog-#{@project_name}-#{time_prefix}.csv.gz"
      query_array = [
        [
          "COPY ( select *,",
          "to_json(new_values) as new_values_json,",
          "to_json(old_values) as old_values_json ",
          "FROM barkdata.changelog",
          "WHERE archived = false AND change_id <= #{latest_change_id}",
          "order by change_id asc ) ",
          "TO STDOUT",
          "WITH CSV HEADER;"
        ].join(' ')
      ]
      sanitized_query = ActiveRecord::Base.send(:sanitize_sql_array, query_array)
      raw_connection = ActiveRecord::Base.connection.raw_connection
      raw_connection.exec(sanitized_query)
      row_count = 0

      File.open(tmp_filepath, "wb") do |file|
        gz = Zlib::GzipWriter.new(file)
        while row = raw_connection.get_copy_data
          row_count += 1
          Rails.logger.info "Barkdata::Changelog.archive_to_s3: #{row_count} rows dumped." if row_count % 10000 == 0
          gz << row
        end
        gz.close
      end
      s3_key = Barkdata::S3.upload(tmp_filepath, "internal_data/barkdata_changelog/extracted/#{@project_name}")
      self.mark_as_archived(latest_change_id)
      File.delete(tmp_filepath)
      Rails.logger.info "Barkdata::Changelog.archive_to_s3: Finished. Dumped #{row_count} total rows in changelog."
      s3_key
    end

    def self.cleanup_archived_rows
      query_array = [
        "DELETE FROM barkdata.changelog WHERE archived = true"
      ]
      sanitized_query = ActiveRecord::Base.send(:sanitize_sql_array, query_array)
      results = ActiveRecord::Base.connection.select_all(sanitized_query)
      results.first
    end

    protected

    def self.get_latest_change_id
      query_array = [
        "SELECT max(change_id) as max_change_id FROM barkdata.changelog WHERE archived = false"
      ]
      sanitized_query = ActiveRecord::Base.send(:sanitize_sql_array, query_array)
      results = ActiveRecord::Base.connection.select_all(sanitized_query)
      results.first.try(:[], 'max_change_id').to_i
    end

    def self.mark_as_archived change_id=nil
      query_array = [
        "UPDATE barkdata.changelog SET archived = true WHERE change_id <= #{change_id.to_i} AND archived = false"
      ]
      sanitized_query = ActiveRecord::Base.send(:sanitize_sql_array, query_array)
      results = ActiveRecord::Base.connection.select_all(sanitized_query)
      results.first
    end

  end

end
