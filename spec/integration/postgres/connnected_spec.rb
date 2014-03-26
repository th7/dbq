require 'spec_helper'

describe 'a database connection exists' do
  it 'does not raise an error' do
    expect { ActiveRecord::Base.connection.execute('select 1') }.not_to raise_error
  end
end
