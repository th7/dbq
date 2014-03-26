require 'active_record'
require 'active_support/inflector'
require 'redis'

Gem.find_files("dbq/**/*.rb").each { |path| require path }

module DBQ
  class Error < StandardError; end
end
