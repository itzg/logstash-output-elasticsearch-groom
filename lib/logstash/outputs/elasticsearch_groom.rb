# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash-output-elasticsearch_groom_jars"

class LogStash::Outputs::ElasticsearchGroom < LogStash::Outputs::Base
  config_name "elasticsearch_groom"

  public
  def register
    require "logstash/outputs/elasticsearch_groom/es_accessor"
    options = {}
    @esAccess = LogStash::Outputs::EsGroom::EsAccessor.new(options)
  end # def register

  public
  def receive(event)
    return unless output?(event)
    return "Event received"
  end # def event
end
