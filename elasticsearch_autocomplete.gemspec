# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elasticsearch_autocomplete/version'

Gem::Specification.new do |gem|
  gem.name          = "elasticsearch_autocomplete"
  gem.version       = ElasticsearchAutocomplete::VERSION
  gem.authors       = ["Alex Leschenko"]
  gem.email         = ["leschenko.al@gmail.com"]
  gem.summary       = %q{Elasticsearch autocomplete for rails models}
  gem.description   = %q{Simple autocomplete for rails models using awesome elasticsearch and tire gem}
  gem.homepage      = "https://github.com/leschenko/elasticsearch_autocomplete"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_runtime_dependency 'tire'

end
