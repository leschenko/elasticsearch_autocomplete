require 'tire'
require 'elasticsearch_autocomplete/version'
require 'elasticsearch_autocomplete/analyzers'
require 'elasticsearch_autocomplete/model_addition'
require 'elasticsearch_autocomplete/railtie' if Object.const_defined?(:Rails)

module ElasticsearchAutocomplete
  mattr_accessor :defaults
  mattr_accessor :enable_indexing
  self.enable_indexing = true

  mattr_accessor :elasticsearch_version
  self.elasticsearch_version = '2.x'

  def self.es2?
    elasticsearch_version && elasticsearch_version.start_with?('2')
  end

  def self.default_index_prefix
    Object.const_defined?(:Rails) ? ::Rails.application.class.name.split('::').first.downcase : nil
  end

  self.defaults = {attr: :name, localized: false, mode: :word, index_prefix: default_index_prefix}

  MODES = {
      word: {base: 'ac', word: 'ac_word'},
      phrase: {base: 'ac'},
      full: {base: 'ac', full: 'ac_full'}
  }

  class << self
    def val_to_terms(val, zero=false)
      return [] unless val
      return val if val.is_a?(Array)
      return [true] if val == 'true'
      return [false] if val == 'false'
      a = val.to_s.split(',').map(&:to_i)
      zero ? a : a.reject(&:zero?)
    end

    def without_indexing
      original_setting = enable_indexing
      self.enable_indexing = false
      begin
        yield
      ensure
        self.enable_indexing = original_setting
      end
    end
  end
end
