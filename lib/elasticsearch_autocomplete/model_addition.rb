module ElasticsearchAutocomplete
  module ModelAddition
    def self.included(base)
      base.send :extend, SingletonMethods
    end

    module SingletonMethods
      def ac_setup_es
        include InstanceMethods
        include Elasticsearch::Model
        include Elasticsearch::Model::Adapter::ActiveRecord

        if ElasticsearchAutocomplete.defaults[:commit_callbacks]
          after_commit -> { ac_store_document(:index) }, on: :create
          after_commit -> { ac_store_document(:update) }, on: :update
          after_commit -> { ac_store_document(:delete) }, on: :destroy
        else
          after_create -> { ac_store_document(:index) }
          after_update -> { ac_store_document(:update) }
          after_destroy -> { ac_store_document(:delete) }
        end

        index_prefix ElasticsearchAutocomplete.defaults[:index_prefix] if ElasticsearchAutocomplete.defaults[:index_prefix]
      end

      def ac_field(*args)
        extend ClassMethods

        ac_setup_es

        class_attribute :ac_opts, :ac_attr, :ac_search_attrs, :ac_search_fields, :ac_mode_config, instance_writer: false
        options = args.extract_options!
        self.ac_opts = options.reverse_merge(ElasticsearchAutocomplete.defaults)
        self.ac_attr = args.first || ElasticsearchAutocomplete.defaults[:attr]

        self.ac_mode_config = ElasticsearchAutocomplete::MODES[ac_opts[:mode]]

        self.ac_search_attrs = ac_opts[:search_fields] || (ac_opts[:localized] ? I18n.available_locales.map { |l| "#{ac_attr}_#{l}" } : [ac_attr])
        self.ac_search_fields = ac_search_attrs.map { |attr| ac_mode_config.values.map { |prefix| "#{prefix}_#{attr}" } }.flatten

        define_ac_index(ac_opts[:mode]) unless options[:skip_settings]
      end
    end

    module ClassMethods
      def ac_search(query, options={})
        options.reverse_merge!({per_page: 50, search_fields: ac_search_fields, load: false})

        if query.size.zero?
          query = {match_all: {}}
        else
          query = {multi_match: {query: query, fields: options[:search_fields]}}
        end

        sort = []
        if options[:geo_order] && options[:with]
          lat = options[:with].delete('lat').presence
          lon = options[:with].delete('lon').presence
          if lat && lon
            sort << {_geo_distance: {lat_lon: [lat, lon].join(','), order: 'asc', unit: 'km'}}
          end
        end
        sort << {options[:order] => options[:sort_mode] || 'asc'} if options[:order].present?

        filter = {}
        if options[:with].present?
          filter[:and] = {filters: options[:with].map { |k, v| {terms: {k => ElasticsearchAutocomplete.val_to_terms(v)}} }}
        end
        if options[:without].present?
          filter[:and] = {filters: []}
          options[:without].each do |k, v|
            filter[:and][:filters] << {not: {terms: {k => ElasticsearchAutocomplete.val_to_terms(v, true)}} }
          end
        end

        per_page = options[:per_page] || 50
        page = options[:page].presence || 1
        from = per_page.to_i * (page.to_i - 1)

        __elasticsearch__.search query: query, sort: sort, filter: filter, size: per_page, from: from
      end

      def define_ac_index(mode=:word)
        model = self
        model_ac_search_attrs = model.ac_search_attrs
        settings ElasticsearchAutocomplete::Analyzers::AC_BASE do
          mapping do
            model_ac_search_attrs.each do |attr|
              indexes attr, model.ac_index_config(attr, mode)
            end
          end
        end
      end

      def ac_index_config(attr, mode=:word)
        defaults = {type: 'string', search_analyzer: 'ac_search', include_in_all: false}
        fields = case mode
                   when :word
                     {
                         attr => {type: 'string'},
                         "#{ac_mode_config[:base]}_#{attr}" => defaults.merge(index_analyzer: 'ac_edge_ngram'),
                         "#{ac_mode_config[:word]}_#{attr}" => defaults.merge(index_analyzer: 'ac_edge_ngram_word')
                     }
                   when :phrase
                     {
                         attr => {type: 'string'},
                         "#{ac_mode_config[:base]}_#{attr}" => defaults.merge(index_analyzer: 'ac_edge_ngram')
                     }
                   when :full
                     {
                         attr => {type: 'string'},
                         "#{ac_mode_config[:base]}_#{attr}" => defaults.merge(index_analyzer: 'ac_edge_ngram', boost: 3),
                         "#{ac_mode_config[:full]}_#{attr}" => defaults.merge(index_analyzer: 'ac_edge_ngram_full')
                     }
                 end
        {type: 'multi_field', fields: fields}
      end
    end

    module InstanceMethods
      def to_indexed_json
        for_json = {}
        attrs = [:id, :created_at] + self.class.ac_search_attrs
        attrs.each do |attr|
          for_json[attr] = send(attr)
        end
        MultiJson.encode(for_json)
      end

      def ac_store_document(action)
        return true unless ElasticsearchAutocomplete.enable_indexing
        __elasticsearch__.send("#{action}_document")
      end
    end
  end
end
