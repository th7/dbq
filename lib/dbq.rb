Gem.find_files("dbq/**/*.rb").each { |path| require path }
require 'active_record'

module DBQ
  class DBQ::Error < StandardError; end
end
