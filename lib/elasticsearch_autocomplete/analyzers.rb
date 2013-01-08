module ElasticsearchAutocomplete
  module Analyzers

    AC_TOKENIZERS = {
        :ac_edge_ngram => {
            :type => 'edgeNGram',
            :min_gram => 1,
            :max_gram => 50,
            :side => 'front'
        },
        :ac_edge_ngram_full => {
            :type => 'nGram',
            :min_gram => 1,
            :max_gram => 50
        }
    }

    AC_FILTERS = {
        :ac_edge_ngram => {
            :type => 'edgeNGram',
            :min_gram => 1,
            :max_gram => 50,
            :side => 'front'
        }
    }

    AC_ANALYZERS = {
        :ac_edge_ngram => {
            :type => 'custom',
            :tokenizer => 'ac_edge_ngram',
            :filter => %w(lowercase asciifolding)
        },
        :ac_edge_ngram_full => {
            :type => 'custom',
            :tokenizer => 'ac_edge_ngram_full',
            :filter => %w(lowercase asciifolding)
        },
        :ac_edge_ngram_word => {
            :type => 'custom',
            :tokenizer => 'standard',
            :filter => %w(lowercase asciifolding ac_edge_ngram)
        },
        :ac_search => {
            :type => 'custom',
            :tokenizer => 'keyword',
            :filter => %w(lowercase asciifolding)
        }
    }

    AC_BASE = {
        :analysis => {
            :analyzer => AC_ANALYZERS,
            :tokenizer => AC_TOKENIZERS,
            :filter => AC_FILTERS
        }
    }

  end
end
