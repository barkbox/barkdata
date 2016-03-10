require 'singleton'

module Barkdata

  class Config
    include Singleton

    attr_accessor :registered_objects, :project_name, :bucket, :enabled, :file_row_limit

    def initialize
      @registered_objects = {}
      @project_name = ENV['BARKDATA_PROJECT_NAME'] || 'unknown'
      @bucket = ENV['BARKDATA_BUCKET'] || 'unknown-bucket'
      @enabled = false
      @file_row_limit = ENV['FILE_ROW_LIMIT'] || 50000
      super
    end

  end

end
