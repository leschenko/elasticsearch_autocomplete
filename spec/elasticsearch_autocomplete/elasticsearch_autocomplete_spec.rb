require 'spec_helper'

class ActiveModelUser < ActiveModelUserBase
  ac_field :full_name
end

describe ElasticsearchAutocomplete do
  subject { ActiveModelUser }
  before :all do
    ActiveModelUser.setup_index
  end

  it 'add ac_search method' do
    should respond_to(:ac_search)
  end

  it 'define to_indexed_json method' do
    ActiveModelUser.new(:full_name => 'test').to_indexed_json.should == '{"id":null,"created_at":null,"full_name":"test"}'
  end

  describe 'default settings' do
    around do |example|
      old_settings = ElasticsearchAutocomplete.defaults
      example.run
      ElasticsearchAutocomplete.defaults = old_settings
    end

    it 'allow to change default settings' do
      ElasticsearchAutocomplete.defaults = {:attr => :test, :localized => true, :mode => :phrase}
      ElasticsearchAutocomplete.defaults.should == {:attr => :test, :localized => true, :mode => :phrase}
    end
  end
end

shared_examples 'basic autocomplete' do |model|
  it 'suggest for beginning of the source' do
    model.ac_search('Joyce Flores').to_a.should_not be_empty
  end

  it 'suggest for for full match' do
    model.ac_search('Lau').to_a.should_not be_empty
  end

  it 'don\'t suggest for unmatched term' do
    model.ac_search('Lai').to_a.should be_empty
  end
end