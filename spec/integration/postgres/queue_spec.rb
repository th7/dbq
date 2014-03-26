require 'spec_helper'

class TestQueue < DBQ::Queue; end

describe TestQueue do
  context 'its anonymous model class' do
    let(:model) { TestQueue.instance_variable_get(:@model) }
    it 'has a database connection' do
      expect { model.all }.not_to raise_error
    end

    it 'connects to the correct table' do
      expect(model.table_name).to eq 'test_queues'
    end
  end

  context 'its mem_queue class' do
    let(:mem_queue) { TestQueue.instance_variable_get(:@mem_queue) }
    it 'has the correct queue_key' do
      expect(mem_queue.send(:queue_key)).to eq 'DBQ:test_queues'
    end
  end
end
