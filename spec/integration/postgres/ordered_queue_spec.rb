require 'spec_helper'

class TestOrderedQueue < ActiveRecord::Base
  include DBQ::OrderedQueue
  enforces_order_on :fk1, :fk2
end

describe TestOrderedQueue do
  let(:klass) { TestOrderedQueue }

  before do
    # klass.logger = Logger.new(STDOUT)
    klass.delete_all
  end

  after do
    klass.delete_all
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
      expect { klass.pop }.to change { klass.count }.from(1).to(0)
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

  context 'items are not order constrained' do
    before do
      klass.push(data: 1)
      klass.push(data: 2)
      klass.push(data: 3)
    end

    context 'multiple items are popped simultaneously' do
      it 'only pops each item once' do
        result_threads = [
          simultaneous_pop,
          simultaneous_pop,
          simultaneous_pop
        ]
        values = result_threads.map(&:value)
        data = values.map(&:data)
        expect(data.sort).to eq [ 1, 2, 3 ]
      end
    end

  end

  context 'order enforcement matches partially' do
    before do
      klass.push(fk1: 1, fk2: 1, data: 1)
      klass.push(fk1: 1, fk2: 2, data: 2)
      klass.push(fk1: 1, fk2: 3, data: 3)
    end

    context 'multiple items are popped simultaneously' do
      it 'only pops each item once' do
        result_threads = [
          simultaneous_pop,
          simultaneous_pop,
          simultaneous_pop
        ]
        values = result_threads.map(&:value)
        data = values.map(&:data)
        expect(data.sort).to eq [ 1, 2, 3 ]
      end
    end
  end

  context 'order enforcement matches' do
    before do
      klass.push(fk1: 1, fk2: 1, data: 1)
      klass.push(fk1: 1, fk2: 1, data: 2)
      klass.push(fk1: 1, fk2: 1, data: 3)
    end

    it 'pops items in order' do
      expect([klass.pop.data, klass.pop.data, klass.pop.data]).to eq [ 1, 2, 3 ]
    end

    context 'multiple items are popped simultaneously' do
      it 'only pops each item once' do
        result_threads = [
          simultaneous_pop,
          simultaneous_pop,
          simultaneous_pop
        ]
        values = result_threads.map(&:value).compact.sort
        # ids = values.map(&:id)
        expect(values.uniq).to eq values
      end
    end

    context 'an item is being processed' do
      it 'does not return order-enfoced items' do
        thread = slow_threaded_pop # work on an item
        sleep 0.05 # wait for threaded pop to go first
        begin
          expect(klass.count).to eq 3
          expect(klass.first.checked_out_at).not_to be_nil
          expect(klass.last.checked_out_at).to be_nil
          expect(klass.pop).to be_nil
        ensure
          thread.kill
        end
      end
      context 'a non-order-enforced item also exists' do
        before do
          klass.push(fk1: 1, fk2: 4, data: 4)
        end

        it 'returns the non-order-enforced item' do
          thread = slow_threaded_pop # work on an item
          sleep 0.05 # wait for threaded pop to go first
          begin
            expect(klass.count).to eq 4
            expect(klass.first.checked_out_at).not_to be_nil
            expect(klass.last.checked_out_at).to be_nil
            expect(klass.pop.data).to eq 4
          ensure
            thread.kill
          end
        end
      end
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

def slow_threaded_pop
  thread = Thread.new do
    klass.connection_pool.with_connection do
      klass.transaction do
        klass.pop
        sleep 2
      end
    end
  end
  thread.abort_on_exception = true
  thread
end
