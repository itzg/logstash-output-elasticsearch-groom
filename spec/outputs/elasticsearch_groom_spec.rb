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

    event = LogStash::Event.new('@timestamp' => '2015-03-15T00:00:00')

    expect(es_accessor).to receive(:matching_indices)
                               .with('logstash-*', 'open')
                               .and_return(['logstash-2015.03.12'])
    expect(es_accessor).not_to receive(:close_indices)
    expect(es_accessor).not_to receive(:delete_indices)
    output.receive event
  end

  it 'should act upon just older ones' do
    output = outputClass.new('action' => 'delete', 'age_cutoff' => '4w')
    output.register

    event = LogStash::Event.new('@timestamp' => '2015-03-15T00:00:00')

    expect(es_accessor).to receive(:matching_indices)
                               .with('logstash-*', 'open')
                               .and_return(%w(logstash-2015.03.12 logstash-2015.02.13 logstash-2015.02.12))
    expect(es_accessor).not_to receive(:close_indices)
    expect(es_accessor).to receive(:delete_indices)
                               .with(%w(logstash-2015.02.13 logstash-2015.02.12))
                               .once
    output.receive event

  end
end
