require 'spec_helper'

class TestQueue < DBQ::Queue; end

describe TestQueue do
  let(:model) { TestQueue.instance_variable_get(:@model) }
  let(:mem_queue) { TestQueue.instance_variable_get(:@mem_queue) }
  let(:redis) { Redis.new(db: 14) }
  before do
    mem_queue.stub(:redis) { redis }
  end

  after do
    redis.flushdb
  end

  context 'its anonymous model class' do
    it 'has a database connection' do
      expect { model.all }.not_to raise_error
    end

    it 'connects to the correct table' do
      expect(model.table_name).to eq 'test_queues'
    end
  end

  context 'its mem_queue class' do
    it 'has the correct queue_key' do
      expect(mem_queue.send(:queue_key)).to eq 'DBQ:test_queues'
    end
  end

  describe '#push' do
    it 'creates the expected associated data' do
      TestQueue.send(:query_next_val)
      TestQueue.push('data')

      expect(model.first.attributes).to eq({
        'action' => TestQueue::PUSH,
        'data' => {'id' => '2', 'data' => 'data'},
        'id' => 1,
        'item_id' => 2
      })

      expect(mem_queue.pop).to eq({
        'id' => '2',
        'data' => 'data'
      })
    end
  end
end
