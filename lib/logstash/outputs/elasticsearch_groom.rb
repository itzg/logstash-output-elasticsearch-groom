# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
# require "logstash-output-elasticsearch-groom_jars"
# require "logstash/outputs/elasticsearch_groom/es_accessor"

class LogStash::Outputs::ElasticsearchGroom < LogStash::Outputs::Base
  config_name "elasticsearch_groom"

  public
  def register
    options = {}
    # @esAccess = LogStash::Outputs::ElasticsearchGroom::EsAccessor.new(options)
  end # def register

  public
  def receive(event)
    return unless output?(event)
    return "Event received"
  end # def event
end
