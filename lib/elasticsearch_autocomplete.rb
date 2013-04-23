require 'tire'
require 'elasticsearch_autocomplete/version'
require 'elasticsearch_autocomplete/analyzers'
require 'elasticsearch_autocomplete/model_addition'
require 'elasticsearch_autocomplete/railtie' if defined? Rails

module ElasticsearchAutocomplete
  mattr_accessor :defaults

  def self.default_index_prefix
    Object.const_defined?('Rails') ? ::Rails.application.class.name.split('::').first.downcase : nil
  end

  self.defaults = {:attr => :name, :localized => false, :mode => :word, :index_prefix => default_index_prefix}

  MODES = {
      :word => {:base => 'ac', :word => 'ac_word'},
      :phrase => {:base => 'ac'},
      :full => {:base => 'ac', :full => 'ac_full'}
  }

  def self.val_to_array(val, zero=false)
    return [] unless val
    return val if val.is_a?(Array)
    a = val.to_s.split(',').map(&:to_i)
    zero ? a : a.reject(&:zero?)
  end
end
