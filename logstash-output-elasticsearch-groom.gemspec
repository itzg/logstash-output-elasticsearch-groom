Gem::Specification.new do |s|
  s.name = 'logstash-output-elasticsearch-groom'
  s.version         = "0.1.0"
  s.licenses = ["Apache License (2.0)"]
  s.summary = "Grooms the time-series Elastichsearch indices."
  s.description = "Grooms the time-series Elastichsearch indices."
  s.authors = ["Geoff Bourne"]
  s.email = "itzgeoff@gmail.com"
  s.homepage = "https://github.com/itzg/logstash-output-elasticsearch-groom"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency 'elasticsearch', ['>= 1.0.6', '~> 1.0']
  s.add_runtime_dependency "logstash-core", ">= 1.4.0", "< 2.0.0"
  s.add_runtime_dependency "logstash-codec-plain"

  s.add_development_dependency 'logstash-input-generator'
  s.add_development_dependency "logstash-devutils"
end
