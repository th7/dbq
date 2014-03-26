module Migrate
  class CreateTestQueues < ActiveRecord::Migration
    def change
      create_table :test_queues do |t|
        t.string :queue_name
        t.json :wrapped_data
      end
    end
  end
end
