require 'barkdata'
require 'rails'

module Barkdata
  class Railtie < Rails::Railtie
    rake_tasks { load 'tasks/barkdata.rake' }
  end
end
