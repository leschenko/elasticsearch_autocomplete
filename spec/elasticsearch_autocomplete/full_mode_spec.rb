require 'spec_helper'

class ActiveModelUserFull < ActiveModelUserBase
  ac_field :full_name, :mode => :full
end

describe ':full mode autocomplete' do
  before :all do
    ActiveModelUserFull.setup_index
  end

  it 'have :full mode' do
    ActiveModelUserFull.ac_opts[:mode].should == :full
  end

  it_behaves_like 'basic autocomplete', ActiveModelUserFull

  it 'suggest from the middle of the word' do
    ActiveModelUserFull.ac_search('becc').to_a.should_not be_empty
  end

  it 'suggest for each word of the source' do
    ActiveModelUserFull.ac_search('Flores').map(&:full_name).should == ['Joyce Flores']
  end

  it 'suggest with relevance order' do
    ActiveModelUserFull.ac_search('Lau').map(&:full_name).should == ['Laura Larson', 'Larson Laura']
  end
end