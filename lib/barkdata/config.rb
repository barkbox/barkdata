require 'singleton'

module Barkdata

  class Config
    include Singleton

    attr_accessor :registered_objects, :project_name, :bucket

    def initialize
      @registered_objects = {}
      @project_name = ENV['BARKDATA_PROJECT_NAME'] || 'unknown'
      @bucket = ENV['BARKDATA_BUCKET'] || 'unknown-bucket'
      super
    end

  end

end
