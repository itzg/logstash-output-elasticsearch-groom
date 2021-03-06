Gem::Specification.new do |s|
  s.name = 'logstash-output-elasticsearch_groom'
  s.version = '0.2.0'
  s.licenses = ["Apache License (2.0)"]
  s.summary = "Grooms time-series Elastichsearch indices."
  s.description = "A logstash output plugin that will perform event triggered grooming (aka pruning) of time-series indices especially those created by logstash-output-elasticsearch."
  s.authors = ["Geoff Bourne"]
  s.email = "itzgeoff@gmail.com"
  s.homepage = "https://github.com/itzg/logstash-output-elasticsearch-groom"
  s.require_paths = ["lib"]

  # Files
  s.files << `git ls-files`.split($\)
  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency 'elasticsearch', '~> 2.0', '>= 2.0.0'
  s.add_runtime_dependency "logstash-core", ">= 2.3.0", "< 3.0.0"
  s.add_runtime_dependency 'logstash-codec-plain', '~> 0'

  s.add_development_dependency 'logstash-devutils', '~> 0'
end
