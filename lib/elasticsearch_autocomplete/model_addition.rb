module ElasticsearchAutocomplete
  module ModelAddition
    def self.included(base)
      base.send :extend, SingletonMethods
    end

    module SingletonMethods
      def elasticsearch(options={})
        include Tire::Model::Search
        unless options.delete(:skip_after_save)
          after_save lambda { tire.update_index }
        end
        after_destroy lambda { tire.update_index }
        index_prefix ElasticsearchAutocomplete.defaults[:index_prefix]
      end

      def ac_field(*args, &block)
        options = args.extract_options!

        include InstanceMethods
        extend ClassMethods

        elasticsearch(options)

        class_attribute :ac_opts, :ac_attr, :instance_writer => false
        self.ac_opts = options.reverse_merge(ElasticsearchAutocomplete.defaults)
        self.ac_attr = args.first || ElasticsearchAutocomplete.defaults[:attr]

        define_ac_index(ac_opts[:mode]) unless options[:skip_settings]
      end
    end

    module ClassMethods
      def ac_search(query, options={})
        options.reverse_merge!({:per_page => 50, :search_fields => ac_search_fields})

        tire.search :per_page => options[:per_page] do
          query do
            if query.size.zero?
              all
            else
              match options[:search_fields], query
            end
          end

          sort { by options[:order], options[:sort_mode] || 'asc' } if options[:order].present?

          filter(:and, :filters => options[:with].map { |k, v| {:terms => {k => ElasticsearchAutocomplete.val_to_array(v)}} }) if options[:with].present?
          if options[:without].present?
            options[:without].each do |k, v|
              filter(:not, {:terms => {k => ElasticsearchAutocomplete.val_to_array(v, true)}})
            end
          end
        end
      end

      def ac_search_attrs
        @ac_search_attrs ||=
            if ac_opts[:search_fields]
              ac_opts[:search_fields]
            else
              if ac_opts[:localized]
                I18n.available_locales.map { |l| "#{ac_attr}_#{l}" }
              else
                [ac_attr]
              end
            end
      end

      def for_input_token(r, attr='name_ru')
        {:name => r[attr], :id => r.id}
      end

      def ac_mode_config
        ElasticsearchAutocomplete::MODES[ac_opts[:mode]]
      end

      def define_ac_index(mode=:word)
        model = self
        settings ElasticsearchAutocomplete::Analyzers::AC_BASE do
          mapping do
            ac_search_attrs.each do |attr|
              indexes attr, model.ac_index_config(attr, mode)
            end
          end
        end
      end

      def ac_index_config(attr, mode=:word)
        defaults = {:type => 'string', :search_analyzer => 'ac_search', :include_in_all => false}
        fields = case mode
                   when :word
                     {
                         attr => {:type => 'string'},
                         "#{ac_mode_config[:base]}_#{attr}" => defaults.merge(:index_analyzer => 'ac_edge_ngram'),
                         "#{ac_mode_config[:word]}_#{attr}" => defaults.merge(:index_analyzer => 'ac_edge_ngram_word')
                     }
                   when :phrase
                     {
                         attr => {:type => 'string'},
                         "#{ac_mode_config[:base]}_#{attr}" => defaults.merge(:index_analyzer => 'ac_edge_ngram')
                     }
                   when :full
                     {
                         attr => {:type => 'string'},
                         "#{ac_mode_config[:base]}_#{attr}" => defaults.merge(:index_analyzer => 'ac_edge_ngram', :boost => 3),
                         "#{ac_mode_config[:full]}_#{attr}" => defaults.merge(:index_analyzer => 'ac_edge_ngram_full')
                     }
                 end
        {:type => 'multi_field', :fields => fields}
      end

      def ac_search_fields
        @ac_search_fields ||= ac_search_attrs.map { |attr| ac_mode_config.values.map { |prefix| "#{prefix}_#{attr}" } }.flatten
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
    end
  end
end
