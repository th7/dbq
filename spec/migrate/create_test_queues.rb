module Migrate
  class CreateTestQueues < ActiveRecord::Migration
    def change
      create_table :test_queues do |t|
        t.integer :item_id
        t.string :action
        t.json :data
      end
    end
  end
end
