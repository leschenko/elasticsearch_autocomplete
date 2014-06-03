require 'active_model'
require 'elasticsearch/model'
require 'active_support/core_ext'
require 'elasticsearch_autocomplete'

Elasticsearch::Model.client = Elasticsearch::Client.new host: "http://localhost:#{ENV['ES_PORT'] || 9200}", log: ENV['ES_LOGGER'], trace: ENV['ES_LOGGER']
ElasticsearchAutocomplete.defaults[:commit_callbacks] = false

I18n.available_locales = [:en, :ru]

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:expect, :should]
  end
end

class ActiveModelBase
  include ActiveModel::AttributeMethods
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Naming

  extend ActiveModel::Callbacks
  define_model_callbacks :create, :update, :destroy

  include ElasticsearchAutocomplete::ModelAddition

  attr_reader :attributes
  attr_accessor :id, :created_at

  def initialize(attributes = {})
    @attributes = attributes
  end

  def method_missing(id, *args, &block)
    attributes[id.to_sym] || attributes[id.to_s] || super
  end

  def persisted?
    true
  end

  def save
    run_callbacks(:create) {}
  end

  def destroy
    run_callbacks(:destroy) { @destroyed = true }
  end

  def destroyed?
    !!@destroyed
  end

  def self.setup_index
    __elasticsearch__.create_index! force: true, index: index_name
    populate
    __elasticsearch__.refresh_index!
  end
end

class StubModelBase < ActiveModelBase
  def self.test_data
    ['Joyce Flores', 'Rebecca Nelson', 'Larson Laura', 'Laura Larson']
  end

  def self.populate
    test_data.each_with_index do |name, id|
      u = new(:full_name => name)
      u.id = id
      u.save
    end
  end
end
