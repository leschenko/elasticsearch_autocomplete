require 'spec_helper'

class ActiveModelUserPhrase < StubModelBase
  ac_field :full_name, :mode => :phrase
end

describe ':phrase mode autocomplete' do
  let(:model) { ActiveModelUserPhrase }
  before :all do
    @model = ActiveModelUserPhrase
    @model.setup_index
  end

  it 'have :phrase mode' do
    @model.ac_opts[:mode].should == :phrase
  end

  it_behaves_like 'basic autocomplete', ActiveModelUserPhrase

  it 'don\'t suggest from the middle of the word' do
    @model.ac_search('becca').to_a.should be_empty
  end

  it 'don\'t for each word of the source' do
    @model.ac_search('Flores').map(&:full_name).should be_empty
  end
end