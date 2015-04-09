# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'logstash-output-elasticsearch_groom_jars'
require 'java'

class LogStash::Outputs::ElasticsearchGroom < LogStash::Outputs::Base
  config_name "elasticsearch_groom"

  config :index, :required => true, :default => "logstash-%{+YYYY.MM.dd}"

  config :host, :validate => :array, :default => "localhost:9200"

  # Specifies if 'open' or 'closed' indices should be considered.
  # Can include/be an event field reference via %{value} substitution
  config :scope, :validate => :string, :default => 'open'

  config :age_cutoff, :validate => :string, :default => '4w'

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

    resolvedScope = event.sprintf(@scope)
    return unless validOption? 'scope', resolvedScope, ['open','closed','both']

    candidates = @esAccess.matching_indices pattern: tsWildcarded, scope: resolvedScope
    puts "Starting with #{candidates}"

    if (tsBitMatched = @index.match /%{\+(.+)}/)
      groomByTime(event, candidates, tsBitMatched)
    else
      @logger.warn "Only 'index' with a timestamp placeholder is supported. Instead had #{resolvedIndex}"
    end

    return "Event received"
  end

  def groomByTime(event, candidates, tsBitMatched)
    ts = event.timestamp # of type Logstash::Timestamp
    resolvedCutoff = event.sprintf(@age_cutoff)
    cutoffMsec = convertCutoff(resolvedCutoff)
    return unless cutoffMsec

    eventDt = Java::OrgJodaTime::DateTime.new ts.to_i*1000
    absCutoffDt = eventDt.minus cutoffMsec
    puts "Cutoff is #{absCutoffDt}"

    dtFormat = Java::OrgJodaTimeFormat::DateTimeFormat.forPattern tsBitMatched[1]
    resolvedIndex = event.sprintf (tsBitMatched.pre_match + '(.+)' + tsBitMatched.post_match)
    indexParseRegex = Regexp.new resolvedIndex
    puts "Index regex is #{indexParseRegex}"

    needsGrooming = candidates.find_all do |i|
      if (matchData = indexParseRegex.match(i))
        indexDt = dtFormat.parseDateTime matchData[1]
        puts "Parsed DateTime of #{i} is #{indexDt}"
        next indexDt.isBefore absCutoffDt
      end
    end
    puts "Found these to groom #{needsGrooming}"

  end

  # Converts the cutoff expression into a duration in milliseconds
  def convertCutoff(cutoffStr)
    matchData = /(\d+)([hdw])/.match(cutoffStr)
    if matchData
      value = matchData[1]
      return value.to_i * 1000 * 3600 * case matchData[2]
        when 'h' then 1
        when 'd' then 24
        when 'w' then 24*7
      end
    else
      @logger.warn("Invalid cutoff of #{cutoffStr}")
      return nil
    end
  end

  # def event

  def validOption?(option, givenValue, validValues)
    valid = validValues.member?(givenValue)
    @logger.warn "#{option} contained an invalid value: #{givenValue}. Valid values are #{validValues}" \
        unless valid
    return valid
  end
end
