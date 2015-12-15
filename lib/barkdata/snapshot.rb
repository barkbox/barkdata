module Barkdata

  class Snapshot

    def initialize
    end

    def self.full_snapshot model
      @project_name = Barkdata::Config.instance.project_name
      table_name = model.table_name
      Rails.logger.info "Barkdata::Snapshot.full_snapshot: table_name=#{table_name.inspect}"
      tmp_filepath = "/tmp/#{table_name}-#{Time.now.utc.strftime("%Y-%m-%d-%H-%M-%S")}.csv.gz"
      query_array = [
        [
          "COPY ( select *, now() at time zone 'utc' as action_timestamp FROM #{table_name}  ) ",
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
          Rails.logger.info "Barkdata::Snapshot.full_snapshot: #{row_count} rows dumped. table=#{table_name.inspect}" if row_count % 10000 == 0
          gz << row
        end
        gz.close
      end
      Rails.logger.info "Barkdata::Snapshot.full_snapshot: Finished. Dumped #{row_count} total rows in table=#{table_name.inspect}"
      s3_key = Barkdata::S3.upload(tmp_filepath, "internal_data/barkdata_snapshot/extracted/#{@project_name}/#{table_name}")
      File.delete(tmp_filepath)
      s3_key
    end

    def self.snapshot_all
      Barkdata::Registry.registered_objects.each do |registered_object|
        registered_object[:base_class].full_snapshot
      end
    end

  end

end
