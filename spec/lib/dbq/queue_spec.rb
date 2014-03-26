require 'spec_helper'

describe DBQ::Queue do
  describe '#initialize' do
    it 'must be subclassed' do
      expect { DBQ::Queue.new }.to raise_error
      expect { Class.new(DBQ::Queue).new }.not_to raise_error
    end
  end
end
