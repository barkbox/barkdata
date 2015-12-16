require_relative 'barkdata/config'
require_relative 'barkdata/s3'
require_relative 'barkdata/registry'
require_relative 'barkdata/changelog'
require_relative 'barkdata/snapshot'
require_relative 'barkdata/schema'

require_relative 'barkdata/railtie' if defined?(Rails)

module Barkdata

  def self.configure(&block)
    Rails.logger.info "Barkdata loading..."
    Rails.application.config.after_initialize do |app|
      Rails.logger.info "Barkdata after_initialize"
      Barkdata::Config.instance.instance_eval(&block)
    end
  end

  def self.enabled?
    Barkdata::Config.instance.enabled
  end

  def self.register(class_name, &block)
    Barkdata::Registry.register(class_name, &block)
  end

  def self.status
    Barkdata::Registry.status
  end

  # Enable change capture on all registered tables.
  def self.enable_changecapture_all
    Rails.logger.info "Barkdata.enable_changecapture_all"
    Barkdata::Changelog.enable_all
  end

  # Disable change capture on all registered tables.
  def self.disable_changecapture_all
    Rails.logger.info "Barkdata.disable_changecapture_all"
    Barkdata::Changelog.disable_all
  end

  # Take dump of barkdata_changecapture table to S3.
  def self.archive_to_s3
    Rails.logger.info "Barkdata.archive_to_s3"
    Barkdata::Changelog.archive_to_s3
  end

  def self.cleanup_archived_rows
    Rails.logger.info "Barkdata.cleanup_archived_rows"
    Barkdata::Changelog.cleanup_archived_rows
  end

  # Take full snapshot of tracked tables.
  def self.full_snapshot_all
    Rails.logger.info "Barkdata.full_snapshot_all"
    Barkdata::Snapshot.snapshot_all
  end

  def self.snapshot_schemas_to_s3
    Rails.logger.info "Barkdata.snapshot_schemas_to_s3"
    Barkdata::Schema.snapshot_to_s3
  end

end
