module Barkdata

  class S3

    def initialize
    end

    def self.upload filepath, prefix=nil
      @project_name = Barkdata::Config.instance.project_name
      @bucket_name = Barkdata::Config.instance.bucket
      prefix ||= "internal_data/barkdata_uncategorized/extracted/#{@project_name}"
      s3_key = [ prefix, File.basename(filepath) ].join('/')
      Rails.logger.info "Barkdata::S3.upload filepath=#{filepath.inspect} to " +
                        "s3_key=#{s3_key.inspect}"
      s3 = AWS::S3.new({
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      })
      bucket = s3.buckets[@bucket_name]
      file = File.open(filepath, 'rb')
      bucket.objects[s3_key].write(file)
      file.close
      Rails.logger.info "Barkdata::S3.upload Finished uploading " +
                        "filepath=#{filepath.inspect} to " +
                        "s3_key=#{s3_key.inspect}"
      return s3_key
    end

  end

end
