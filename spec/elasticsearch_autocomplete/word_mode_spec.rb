require 'spec_helper'

class ActiveModelUserWord < StubModelBase
  ac_field :full_name, mode: :word
end

describe ':word mode autocomplete' do
  before :all do
    @model = ActiveModelUserWord
    @model.setup_index
  end

  it 'have :word mode' do
    @model.ac_opts[:mode].should == :word
  end

  it_behaves_like 'basic autocomplete', ActiveModelUserWord

  it 'don\'t suggest from the middle of the word' do
    @model.ac_search('becca').to_a.should be_empty
  end

  it 'suggest for each word of the source' do
    @model.ac_search('Flores').map(&:full_name).should == ['Joyce Flores']
  end

  it 'suggest with relevance order' do
    @model.ac_search('Lau').map(&:full_name).should == ['Laura Larson', 'Larson Laura']
  end
end