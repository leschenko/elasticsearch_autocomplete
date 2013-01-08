module ElasticsearchAutocomplete
  class Railtie < Rails::Railtie
    initializer 'elasticsearch_autocomplete.model_additions' do
      ActiveSupport.on_load :active_record do
        include ElasticsearchAutocomplete::ModelAddition
      end
    end
  end
end