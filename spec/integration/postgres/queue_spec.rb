require 'spec_helper'

class TestQueue < DBQ::Queue; end

describe TestQueue do
  let(:model) { TestQueue.instance_variable_get(:@model) }
  let(:mem_queue) { TestQueue.instance_variable_get(:@mem_queue) }
  let(:redis) { Redis.new(db: 14) }

  before do
    mem_queue.stub(:redis) { redis }
    model.delete_all
    model.connection.execute("select setval('#{model.table_name}_id_seq', 1)")
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
      TestQueue.push('data')

      expect(model.first.attributes).to eq(
        'id' => 2,
        'wrapped_data' => { 'data' => 'data'}
      )

      expect(mem_queue.pop).to eq(
        'id' => 2,
        'data' => 'data'
      )
    end
  end

  describe '#pop' do
    it 'yields the expected data' do
      TestQueue.push('data')
      result = nil
      TestQueue.pop { |data| result = data }
      expect(result).to eq 'data'
    end
  end
end
