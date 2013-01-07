require 'elasticsearch_autocomplete/version'
require 'elasticsearch_autocomplete/analyzers'
require 'elasticsearch_autocomplete/model_addition'

module ElasticsearchAutocomplete
  mattr_accessor :defaults

  def self.default_index_prefix
    Rails.application.class.name.split('::').first.downcase if Object.const_defined?('Rails')
  end

  self.defaults = {:attr => :name, :localized => false, :mode => :word, :index_prefix => default_index_prefix}

  MODES = {
      :word => {:base => 'ac', :word => 'ac_word'},
      :phrase => {:base => 'ac'},
      :full => {:base => 'ac', :full => 'ac_full'}
  }

  def self.val_to_array(val, zero=false)
    return [] unless val
    a = val.is_a?(Array) ? val : val.to_s.split(',').map(&:to_i)
    zero ? a : a.reject(&:zero?)
  end
end
