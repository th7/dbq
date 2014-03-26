require 'active_record'
Gem.find_files("dbq/**/*.rb").each { |path| require path }

module DBQ
  class DBQ::Error < StandardError; end
end
