namespace :barkdata do

  desc "enable change capture"
  task :enable_changecapture => [:environment] do |t, args|
    Barkdata.enable_changecapture_all
  end

  desc "disable change capture"
  task :disable_changecapture => [:environment] do |t, args|
    Barkdata.disable_changecapture_all
  end

  desc "archive changelog to s3"
  task :archive_to_s3 => [:environment] do |t, args|
    Barkdata.archive_to_s3
  end

  desc "snapshot schemas to s3"
  task :snapshot_schemas_to_s3 => [:environment] do |t, args|
    Barkdata.snapshot_schemas_to_s3
  end

  desc "full snapshot tracked tables to s3"
  task :full_snapshot_all => [:environment] do |t, args|
    Barkdata.full_snapshot_all
  end

  desc "cleanup archived rows"
  task :cleanup_archived_rows => [:environment] do |t, args|
    Barkdata.cleanup_archived_rows
  end

end
