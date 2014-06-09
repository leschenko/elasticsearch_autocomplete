require 'spec_helper'

class ActiveModelUser < StubModelBase
  ac_field :full_name

  def self.test_data
    ['Test User', 'Test User2']
  end

  def self.populate
    test_data.each_with_index do |name, id|
      u = new(full_name: name)
      u.id = id
      u.save
    end
  end

  # Stub for find, which takes in array of ids.
  def self.find(ids)
    ids.map do |id|
      id = id.to_i
      u = new(full_name: test_data[id])
      u.id = id
      u
    end
  end
end

describe ElasticsearchAutocomplete do
  subject { ActiveModelUser }
  before :all do
    ActiveModelUser.setup_index
  end

  it 'add ac_search method' do
    should respond_to(:ac_search)
  end

  it 'indexing enabled by default' do
    ElasticsearchAutocomplete.enable_indexing.should be_truthy
  end

  it 'define to_indexed_json method' do
    ActiveModelUser.new(full_name: 'test').to_indexed_json.should == '{"id":null,"created_at":null,"full_name":"test"}'
  end

  describe 'default settings' do
    around do |example|
      old_settings = ElasticsearchAutocomplete.defaults
      example.run
      ElasticsearchAutocomplete.defaults = old_settings
    end

    it 'allow to change default settings' do
      ElasticsearchAutocomplete.defaults = {attr: :test, localized: true, mode: :phrase, index_prefix: 'test'}
      ElasticsearchAutocomplete.defaults.should == {attr: :test, localized: true, mode: :phrase, index_prefix: 'test'}
    end

    describe 'index prefix' do
      before do
        ElasticsearchAutocomplete.defaults[:index_prefix] = 'my_prefix'
        @klass = Class.new(ActiveModelBase)
        Object.const_set("Rspec#{rand(9999)}", @klass)
        @klass.ac_setup_es
      end

      it 'set index prefix' do
        @klass.index_name.should start_with('my_prefix_rspec')
      end

      it 'keep index prefix once' do
        @klass.ac_setup_es
        @klass.index_name.should start_with('my_prefix_rspec')
      end
    end
  end

  describe '#val_to_terms' do
    it 'empty array if argument is blank' do
      ElasticsearchAutocomplete.val_to_terms(nil).should == []
    end

    it 'array if argument is array' do
      ElasticsearchAutocomplete.val_to_terms([1, 2]).should == [1, 2]
    end

    it 'comma separated values' do
      ElasticsearchAutocomplete.val_to_terms('1,2').should == [1, 2]
    end

    context 'skip zero' do
      it 'skip zero by default' do
        ElasticsearchAutocomplete.val_to_terms('0,1,2').should == [1, 2]
      end

      it 'include zero' do
        ElasticsearchAutocomplete.val_to_terms('0,1,2', true).should == [0, 1, 2]
      end
    end

    context 'boolean' do
      it 'true value' do
        ElasticsearchAutocomplete.val_to_terms('true').should == [true]
      end

      it 'false value' do
        ElasticsearchAutocomplete.val_to_terms('false').should == [false]
      end
    end
  end

  describe 'indexing' do
    it 'enabled by default' do
      record = ActiveModelUser.new(full_name: 'test')
      record.should_receive(:__elasticsearch__).and_return(double('__elasticsearch__').as_null_object)
      record.save
    end

    it 'disabled' do
      record = ActiveModelUser.new(full_name: 'test')
      record.should_not_receive(:__elasticsearch__)
      ElasticsearchAutocomplete.without_indexing { record.save }
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