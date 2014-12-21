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
    expect(subject).to respond_to(:ac_search)
  end

  it 'indexing enabled by default' do
    expect(ElasticsearchAutocomplete.enable_indexing).to be_truthy
  end

  it 'define to_indexed_json method' do
    expect(ActiveModelUser.new(full_name: 'test').to_indexed_json).to eq '{"id":null,"created_at":null,"full_name":"test"}'
  end

  describe 'default settings' do
    around do |example|
      old_settings = ElasticsearchAutocomplete.defaults
      example.run
      ElasticsearchAutocomplete.defaults = old_settings
    end

    it 'allow to change default settings' do
      ElasticsearchAutocomplete.defaults = {attr: :test, localized: true, mode: :phrase, index_prefix: 'test'}
      expect(ElasticsearchAutocomplete.defaults).to eq ({attr: :test, localized: true, mode: :phrase, index_prefix: 'test'})
    end
  end

  describe 'eager loading' do
    it 'does not eager load the records from ac_search by default' do
      results = ActiveModelUser.ac_search('Test User')
      expect(results.to_a).not_to be_empty
      results.map{|x| expect(x.is_a?(ActiveModelUser)).to eq false }
    end

    it 'eager loads the records from ac_search' do
      results = ActiveModelUser.ac_search('Test User', load: true)
      expect(results.to_a).not_to be_empty
      results.map{|x| expect(x.is_a?(ActiveModelUser)).to eq true }
    end
  end

  describe '#val_to_terms' do
    it 'empty array if argument is blank' do
      expect(ElasticsearchAutocomplete.val_to_terms(nil)).to eq []
    end

    it 'array if argument is array' do
      expect(ElasticsearchAutocomplete.val_to_terms([1, 2])).to eq [1, 2]
    end

    it 'comma separated values' do
      expect(ElasticsearchAutocomplete.val_to_terms('1,2')).to eq [1, 2]
    end

    context 'skip zero' do
      it 'skip zero by default' do
        expect(ElasticsearchAutocomplete.val_to_terms('0,1,2')).to eq [1, 2]
      end

      it 'include zero' do
        expect(ElasticsearchAutocomplete.val_to_terms('0,1,2', true)).to eq [0, 1, 2]
      end
    end

    context 'boolean' do
      it 'true value' do
        expect(ElasticsearchAutocomplete.val_to_terms('true')).to eq [true]
      end

      it 'false value' do
        expect(ElasticsearchAutocomplete.val_to_terms('false')).to eq [false]
      end
    end
  end

  describe 'indexing' do
    it 'enabled by default' do
      record = ActiveModelUser.new(full_name: 'test')
      expect(record).to receive(:tire).and_return(double('tire').as_null_object)
      record.save
    end

    it 'disabled' do
      record = ActiveModelUser.new(full_name: 'test')
      expect(record).not_to receive(:tire)
      ElasticsearchAutocomplete.without_indexing { record.save }
    end
  end
end

shared_examples 'basic autocomplete' do |model|
  it 'suggest for beginning of the source' do
    expect(model.ac_search('Joyce Flores').to_a).not_to be_empty
  end

  it 'suggest for for full match' do
    expect(model.ac_search('Lau').to_a).not_to be_empty
  end

  it 'don\'t suggest for unmatched term' do
    expect(model.ac_search('Lai').to_a).to be_empty
  end
end