module Barkdata

  class Schema

    def initialize
    end

    def self.get model
      schema = {
        table_name: model.table_name,
        columns: []
      }
      ignored_columns = Barkdata::Config.instance.registered_objects[model.base_class.name][:ignored_columns]
      column_index = 0
      model.columns.each do |col|
        next if ignored_columns.include?(col.name)
        schema[:columns] << {
          name: col.name,
          sql_type: col.sql_type,
          column_index: column_index
        }
        column_index += 1
      end
      schema
    end

    def self.snapshot_to_s3
      @project_name = Barkdata::Config.instance.project_name
      @s3_prefix = "internal_data/barkdata_schema/#{@project_name}"

      time_prefix = Time.now.utc.strftime("%Y-%m-%d-%H-%M-%S")
      tmp_filepath = "/tmp/barkdata-schema-#{@project_name}-#{time_prefix}.json.gz"

      File.open(tmp_filepath, "wb") do |file|
        gz = Zlib::GzipWriter.new(file)
        Barkdata::Registry.registered_objects.each do |registered_object|
          Rails.logger.info "Barkdata.get_schema: #{registered_object[:base_class]}"
          gz << "#{registered_object[:base_class].get_schema.to_json}\n"
        end
        gz.close
      end
      s3_key = Barkdata::S3.upload(tmp_filepath, @s3_prefix)
      File.delete(tmp_filepath)
      Rails.logger.info "Barkdata::Schema.snapshot_to_s3: Finished."
      s3_key
    end

  end

end
