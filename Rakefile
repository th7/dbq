require "bundler/gem_tasks"
require 'dbq'

namespace :db do
  desc "Seed job schedules"
  namespace :test do
    task :prepare do
      puts `dropdb dbq_test -e`
      puts `createdb dbq_test -e`

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

      Dir['spec/migrate/*.rb'].each { |f| require File.absolute_path(f) }
      migrations = Migrate.constants.map { |c| Migrate.const_get(c) }
      ActiveRecord::Migration.run(*migrations)
    end
  end
end

