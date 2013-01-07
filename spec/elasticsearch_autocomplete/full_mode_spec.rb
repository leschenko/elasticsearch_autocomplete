require 'spec_helper'

class ActiveModelProductFull < StubModelBase
  ac_field :sku, :mode => :full

  def self.test_data
    ['SAMARA', 'A.3103', 'b A.3611', 'kac12 dk/sm']
  end

  def self.populate
    test_data.each_with_index do |name, id|
      u = new(:sku => name)
      u.id = id
      u.save
    end
  end
end

describe ':full mode autocomplete' do
  let(:model) { ActiveModelProductFull }

  before :all do
    model.setup_index
  end

  it 'have :full mode' do
    model.ac_opts[:mode].should == :full
  end

  it 'suggest for beginning of the source' do
    model.ac_search('A.31').to_a.should_not be_empty
  end

  it 'suggest for for full match' do
    model.ac_search('SAMARA').to_a.should_not be_empty
  end

  it 'don\'t suggest for unmatched term' do
    model.ac_search('kac3').to_a.should be_empty
  end

  it 'suggest from the middle of the word' do
    model.ac_search('/sm').to_a.should_not be_empty
  end

  it 'suggest with relevance order' do
    model.ac_search('A.3').map(&:sku).should == ['A.3103', 'b A.3611']
  end
end