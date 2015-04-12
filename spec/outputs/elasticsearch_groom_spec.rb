require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/elasticsearch_groom'
require 'logstash/codecs/plain'
require 'logstash/event'
require 'rspec/mocks'

describe 'outputs/elasticsearch_groom' do
  let(:es_accessor) { double 'LogStash::Outputs::EsGroom::EsAccessor' }
  let(:outputClass) { LogStash::Plugin.lookup("output", "elasticsearch_groom") }

  before do
    allow_any_instance_of(LogStash::Outputs::ElasticsearchGroom).to receive(:create_es_accessor).and_return(es_accessor)
  end

  it 'should work with defaults' do
    output = outputClass.new()
    output.register

    event = LogStash::Event.new(@timestamp => '2015-04-11T00:00:00')

    expect(es_accessor).to receive(:matching_indices)
                               .with('logstash-*', 'open')
                               .and_return(['logstash-2015.04.11'])
    output.receive event
  end
end
