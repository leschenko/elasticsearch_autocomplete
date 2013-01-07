module ElasticsearchAutocomplete
  class Railtie < Rails::Railtie
    initializer 'bit_mask.model_additions' do
      ActiveSupport.on_load :active_record do
        include ElasticsearchAutocomplete::ModelAddition
      end
    end
  end
end