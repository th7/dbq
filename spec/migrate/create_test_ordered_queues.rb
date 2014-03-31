module Migrate
  class CreateTestOrderedQueues < ActiveRecord::Migration
    def change
      create_table :test_ordered_queues do |t|
        t.json :wrapped_data
        t.timestamp :checked_out_at

        t.integer :fk1
        t.integer :fk2
      end
    end
  end
end
