module ElasticsearchAutocomplete
  class Railtie < Rails::Railtie
    initializer 'elasticsearch_autocomplete.model_additions' do

      if defined?(Mongoid::Document)
        ActiveSupport.on_load :mongoid do
          Mongoid::Document.send :include, ElasticsearchAutocomplete::ModelAddition
        end
      else
        ActiveSupport.on_load :active_record do
          ActiveRecord::Base.send :include, ElasticsearchAutocomplete::ModelAddition
        end
      end

    end
  end
end