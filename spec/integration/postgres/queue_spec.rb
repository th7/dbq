require 'spec_helper'

class TestQueue < DBQ::Queue; end

describe TestQueue do
  let(:test_queue) {TestQueue.new('test_queues')}
  let(:model) { test_queue.instance_variable_get(:@model) }
  let(:mem_queue) { test_queue.instance_variable_get(:@mem_queue) }
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
      test_queue.push('data')

      expect(model.first.attributes).to eq(
        'id' => 2,
        'queue_name' => 'test_queues',
        'wrapped_data' => { 'data' => 'data'}
      )

      expect(mem_queue.pop).to eq(
        'id' => 2,
        'data' => 'data'
      )
    end
  end

  describe '#pop' do
    before do
      test_queue.push('data')
    end

    context 'no error is raised' do
      it 'yields the expected data' do
        result = nil
        test_queue.pop { |data| result = data }
        expect(result).to eq 'data'
      end
    end

    context 'an error is raised' do
      it 'pushes the item back to the queue' do
        result = nil
        expect { test_queue.pop { |data| raise } }.to raise_error
        test_queue.pop { |data| result = data }
        expect(result).to eq 'data'
      end

      it 'does not destroy the associated item in the db' do
        expect {
          expect { test_queue.pop { |data| raise } }.to raise_error
        }.not_to change { model.count }
      end
    end
  end
end
