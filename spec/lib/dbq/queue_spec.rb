require 'spec_helper'

describe DBQ::Queue do
  describe '#initialize' do
    it 'should not be initialized' do
      expect { DBQ::Queue.new }.to raise_error
    end
  end
end
