require 'dbq'
require 'pg'
require 'database_cleaner'
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.order = 'random'
end

$redis = Redis.new(db: 14)

# only testing on postgres for now
db = URI.parse('postgres://localhost/dbq_test')
DB_NAME = db.path[1..-1]

ActiveRecord::Base.establish_connection(
  :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
  :host     => db.host,
  :port     => db.port,
  :username => db.user,
  :password => db.password,
  :database => DB_NAME,
  :encoding => 'utf8'
)
