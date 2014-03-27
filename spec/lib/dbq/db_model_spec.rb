require 'spec_helper'

describe DBQ::DbModel do
  let(:db_model) { DBQ::DbModel }
  let!(:mem_queue) { db_model.mem_queue }

  before do
    db_model.table_name = 'test_queues'
  end

  after do
    mem_queue.send(:redis).flushdb
  end

  describe '#push' do
    it 'creates the expected associated data' do
      expect {
        db_model.push('data')
      }.to change {
        db_model.count == 1 && db_model.mem_queue.count == 1
      }.from(false).to(true)

      expect(db_model.first.attributes).to eq(
        'id' => 1,
        'wrapped_data' => { 'data' => 'data'}
      )

      expect(mem_queue.pop).to eq(
        'id' => 1,
        'data' => 'data'
      )
    end
  end

  describe '#pop' do
    before do
      db_model.push('data')
    end

    context 'no error is raised' do
      it 'pops the item off the queue' do
        expect {
          expect(db_model.pop).to eq 'data'
        }.to change {
          db_model.mem_queue.count
        }.from(1).to(0)
      end

      it 'destroys the associated row' do
        expect {
          expect(db_model.pop).to eq 'data'
        }.to change {
          db_model.count
        }.from(1).to(0)
      end
    end

    context 'an error is raised within a transaction' do
      it 'pushes the item back to the queue' do
        expect {
          begin
            db_model.transaction do
              # verify we popped the item
              expect {
                # with the correct data
                expect(db_model.pop).to eq 'data'
              }.to change {
                db_model.mem_queue.count
              }.from(1).to(0)

              # but an exception rolls back the transaction
              raise
            end
          rescue
          end
          # and the item was pushed back onto the queue
        }.not_to change {
          db_model.mem_queue.count
        }.from(1)
      end

      it 'does not destroy the associated item in the db' do
        expect {
          begin
            db_model.transaction do
              # verify we destroyed the item
              expect {
                # it had the correct data
                expect(db_model.pop).to eq 'data'
              }.to change {
                db_model.count
              }.from(1).to(0)

              # but an exception rolls back the transaction
              raise
            end
          rescue
          end
          # and the destroy was rolled back
        }.not_to change {
          db_model.count
        }.from(1)
      end
    end
  end
end
