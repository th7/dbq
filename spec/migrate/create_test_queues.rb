module Migrate
  class CreateTestQueues < ActiveRecord::Migration
    def change
      create_table :test_queues do |t|
        t.integer :item_id
        t.string :action
        t.json :data
      end

      execute 'create sequence test_queues_item_id_sequence'
    end
  end
end
