require 'active_model'
require 'tire'
require 'elasticsearch_autocomplete'

Tire.configure do
  logger 'tmp/elasticsearch.log'
  url 'http://localhost:9200'
  pretty 1
end

#load 'spec/spec_helper.rb'
class StubModelBase
  include ActiveModel::AttributeMethods
  include ActiveModel::Validations
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Naming

  extend ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

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
    _run_save_callbacks do
      #STDERR.puts '[Saving ...]'
    end
  end

  def destroy
    _run_destroy_callbacks do
      #STDERR.puts '[Destroying ...]'
      @destroyed = true
    end
  end

  def destroyed?;
    !!@destroyed;
  end

  def self.setup_index
    tire.index.delete
    tire.create_elasticsearch_index
    populate
    tire.index.refresh
  end
end

class ActiveModelUserBase < StubModelBase

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
