require 'spec_helper'

class TestQueue < ActiveRecord::Base
  include DBQ::Queue
end

describe TestQueue do
  let(:klass) { TestQueue }

  before do
    klass.connection_pool.with_connection do
      klass.delete_all
    end
  end

  after do
    klass.connection_pool.with_connection do
      klass.delete_all
    end
  end

  context 'a single item exists' do
    let(:value) { {'expected' => 'changed_attrs'} }

    before do
      klass.push(data: value)
    end

    it 'can pop the item back out' do
      expect(klass.pop.data).to eq value
    end

    it 'destroys the item' do
      expect { klass.pop.data }.to change { klass.count }.from(1).to(0)
    end

    context 'the transaction is rolled back' do
      it 'does not destroy the item' do
        expect {
          klass.transaction { klass.pop; raise ActiveRecord::Rollback }
        }.not_to change {
          klass.count
        }.from(1)
      end

      it 'resets checked_out_at to nil' do
        expect {
          klass.transaction { klass.pop; raise ActiveRecord::Rollback }
        }.not_to change {
          klass.first.checked_out_at
        }.from(nil)
      end
    end
  end

  context 'multiple items are popped simultaneously' do
    before do
      klass.push(data: 1)
      klass.push(data: 2)
      klass.push(data: 3)
    end

    it 'only pops each item once' do
      result_threads = [
        simultaneous_pop,
        simultaneous_pop,
        simultaneous_pop
      ]
      results = result_threads.map(&:value).map(&:data)
      expect(results.sort).to eq [ 1, 2, 3 ]
    end
  end
end

def simultaneous_pop(at=Time.now + 0.1)
  thread = Thread.new do
    result = nil
    klass.connection_pool.with_connection do
      klass.transaction do
        sleep_for = at - Time.now
        sleep sleep_for if sleep_for > 0
        result = klass.pop
      end
    end
    result
  end
  thread.abort_on_exception = true
  thread
end
