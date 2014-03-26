require 'spec_helper'

describe DBQ::MemQueue do
  let(:mem_queue) { DBQ::MemQueue.new('test_queue') }
  let(:test_redis) { Redis.new(db: 14) }

  before do
    mem_queue.stub(:redis).and_return { test_redis }
  end

  after do
    test_redis.flushdb
  end

  describe '#push' do
    it 'pushes data to the appropriate queue' do
      expect(test_redis).to receive(:lpush).with('DBQ:test_queue', 'data'.to_json)
      mem_queue.push('data')
    end
  end

  describe '#pop' do
    it 'pops data to the appropriate queue' do
      expect(test_redis).to receive(:brpop).with('DBQ:test_queue').and_return(['junk', { 'who' => 'cares' }.to_json])
      mem_queue.pop
    end
  end
end
