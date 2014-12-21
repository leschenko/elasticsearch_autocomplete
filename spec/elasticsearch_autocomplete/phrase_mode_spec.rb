require 'spec_helper'

class ActiveModelUserPhrase < StubModelBase
  ac_field :full_name, mode: :phrase
end

describe ':phrase mode autocomplete' do
  let(:model) { ActiveModelUserPhrase }
  before :all do
    @model = ActiveModelUserPhrase
    @model.setup_index
  end

  it 'have :phrase mode' do
    expect(@model.ac_opts[:mode]).to eq :phrase
  end

  it_behaves_like 'basic autocomplete', ActiveModelUserPhrase

  it 'don\'t suggest from the middle of the word' do
    expect(@model.ac_search('becca').to_a).to be_empty
  end

  it 'don\'t for each word of the source' do
    expect(@model.ac_search('Flores').map(&:full_name)).to be_empty
  end
end