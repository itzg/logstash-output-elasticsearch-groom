# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'logstash-output-elasticsearch_groom_jars'

class LogStash::Outputs::ElasticsearchGroom < LogStash::Outputs::Base
  config_name "elasticsearch_groom"

  config :index, :required => true, :default => "logstash-%{+YYYY.MM.dd}"

  config :host, :validate => :array, :default => "localhost:9200"

  # Specifies if 'open' or 'closed' indices should be considered.
  # Can include/be an event field reference via %{value} substitution
  config :scope, :validate => :string, :default => 'open'

  public
  def register
    require "logstash/outputs/elasticsearch_groom/es_accessor"
    options = {
        host: @host
    }
    @esAccess = LogStash::Outputs::EsGroom::EsAccessor.new(options)
  end # def register

  public
  def receive(event)
    return unless output?(event)

    tsWildcarded = @index.gsub /%{\+.+}/, '*'
    tsWildcarded = event.sprintf tsWildcarded
    puts "tsWildcarded is #{tsWildcarded}"

    resolvedScope = event.sprintf(@scope)
    return unless validOption? 'scope', resolvedScope, ['open','closed','both']

    ts = event.timestamp # of type Logstash::Timestamp

    candidates = @esAccess.matching_indices pattern: tsWildcarded, scope: resolvedScope
    puts "Found #{candidates}"

    return "Event received"
  end # def event

  def validOption?(option, givenValue, validValues)
    valid = validValues.member?(givenValue)
    @logger.warn "#{option} contained an invalid value: #{givenValue}. Valid values are #{validValues}" \
        unless valid
    return valid
  end
end
