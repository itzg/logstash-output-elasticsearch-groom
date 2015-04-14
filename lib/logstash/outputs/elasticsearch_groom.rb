# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'logstash-output-elasticsearch_groom_jars'
require 'java'

# This output grooms the indices created by the `elasticsearch` output plugin. By leveraging the same timestamp-based
# `index` specification, this plugin closes or deletes indices that are older than a configured cutoff.
#
# The actions of this plugin are event-driven, meaning it only evaluates and grooms indices when an event
# is received. Combined with the `logstash-input-heartbeat` plugin, there is some interesting configurations you can setup
# such as:
#
# [source]
# ----------------------------------
# input {
#   heartbeat {
#     type => 'groom'
#     interval => 86400
#     add_field => {
#       scope => 'open'
#       cutoff => '2w'
#       action => 'close'
#     }
#   }
#
#   heartbeat {
#     type => 'groom'
#     interval => 86400
#     add_field => {
#       scope => 'closed'
#       cutoff => '4w'
#       action => 'delete'
#     }
#   }
# }
#
# output {
#   if [type] == 'groom' {
#     elasticsearch_groom {
#        host => 'localhost:9200'
#        index => 'logstash-%{+YYYY.MM.dd}'
#        scope => '%{scope}'
#        age_cutoff => '%{cutoff}'
#        action => '%{action}'
#     }
#   }
# }
# ----------------------------------
class LogStash::Outputs::ElasticsearchGroom < LogStash::Outputs::Base
  config_name 'elasticsearch_groom'

  # Declares a template for matching potential indices to groom. If you're using the output elasticsearch
  # plugin, which is probably why you're here, then this is the same value as `index` over there.
  # It needs to include at least a timestamp placeholder like `%{+YYYY.MM.dd}` where the pattern
  # after the `+` is any http://www.joda.org/joda-time/apidocs/org/joda/time/format/DateTimeFormat.html[valid Joda Time pattern].
  # This can include other event field references via `%{value}` substitution or
  # `*` to wildcard any part of the index name.
  config :index, :validate => :string, :required => true, :default => "logstash-%{+YYYY.MM.dd}"

  # The hostname or IP address of the host to use for Elasticsearch unicast discovery
  # The entries are formatted as `host:port`, where `port` is typically 9200
  config :host, :validate => :array, :default => "localhost:9200"

  # Specifies if 'open' or 'closed' indices should be considered.
  # Can include/be an event field reference via `%{value}` substitution
  config :scope, :validate => :string, :default => 'open'

  # Declares the relative age of indices that will be processed by the action.
  # The allowed values for this are formed as <<number>><<scale>> where
  # scale is 'h' (hours), 'd' (days), 'w' (weeks) and the age is relative
  # to the event's @timestamp.
  # Can include/be an event field reference via `%{value}` substitution
  config :age_cutoff, :validate => :string, :default => '4w'

  # For those indices that are older than the age_cutoff, this is the action
  # to take on those indices. The possible choices are 'close' or 'delete'.
  # Can include/be an event field reference via `%{value}` substitution
  config :action, :validate => :string, :default => 'close'

  # Indicates if incoming events that were successfully used should be cancelled
  config :cancel_when_used, :validate => :boolean, :default => true

  public
  def register
    options = {
        host: @host
    }
    @es_access = create_es_accessor(options)

    raise LogStash::ConfigurationError, "A timestamp placeholder %{+___} is required in the 'index' config of elasticsearch_groom" \
       unless @index.match /%{\+(.+)}/
  end

  protected
  def create_es_accessor(options)
    require 'logstash/outputs/elasticsearch_groom/es_accessor'

    LogStash::Outputs::EsGroom::EsAccessor.new(options)
  end

  # def register

  public
  def receive(event)
    return unless output?(event)

    ts_wildcarded = @index.gsub /%{\+[^}]+}/, '*'
    ts_wildcarded = event.sprintf ts_wildcarded

    resolved_scope = event.sprintf(@scope)
    return unless valid_option? 'scope', resolved_scope, %w(open closed both)

    candidates = @es_access.matching_indices ts_wildcarded, resolved_scope
    @logger.debug? and @logger.debug "Starting with #{candidates}"

    groomed = []
    if (ts_bit_matched = @index.match /%{\+([^}]+)}/)
      groomed = groom_by_time(event, candidates, ts_bit_matched)
    else
      @logger.warn "Only 'index' with a timestamp placeholder is supported. Instead had #{resolvedIndex}"
    end

    # We consumed it, so cancel it
    event.cancel if @cancel_when_used

    "Groomed #{groomed}"
  end


  protected
  def groom_by_time(event, candidates, ts_bit_matched)
    resolved_cutoff = event.sprintf(@age_cutoff)
    cutoff_msec = convert_cutoff(resolved_cutoff)
    return unless cutoff_msec

    event_ts_ms = event.timestamp.to_i*1000
    event_dt = org.joda.time.DateTime.new
    event_dt.set_millis event_ts_ms.to_java(:long)
    abs_cutoff_dt = event_dt.minus cutoff_msec

    @logger.debug? and @logger.debug "Grooming indices older than #{abs_cutoff_dt}"

    dt_format = org.joda.time.format.DateTimeFormat.forPattern ts_bit_matched[1]
    resolved_index = event.sprintf (ts_bit_matched.pre_match + '(.+)' + ts_bit_matched.post_match)
    index_parse_regex = Regexp.new resolved_index
    @logger.debug? and @logger.debug "Index regex is #{index_parse_regex}"

    # Narrow down the candidates to only those that are older than the cutoff
    needs_grooming = candidates.find_all do |i|

      if (match_data = index_parse_regex.match(i))
        index_dt = dt_format.parseDateTime match_data[1]
        @logger.debug? and @logger.debug "Parsed DateTime of #{i} is #{index_dt}"
        next index_dt.isBefore abs_cutoff_dt
      end

    end

    unless needs_grooming.empty?
      resolved_action = event.sprintf @action
      return unless valid_option? 'action', resolved_action, %w(close delete)

      @logger.info? and @logger.info "Performing the action #{resolved_action} on #{needs_grooming}"
      case resolved_action
        when 'close' then
          @es_access.close_indices needs_grooming
        when 'delete' then
          @es_access.delete_indices needs_grooming
        else
          @logger.warn "Action resolved to an unexpected value #{resolved_action}"
      end
    end

    needs_grooming
  end

  # Converts the cutoff expression into a duration in milliseconds
  def convert_cutoff(cutoff_str)
    match_data = /(\d+)([hdw])/.match(cutoff_str)
    if match_data
      value = match_data[1]
      value.to_i * 1000 * 3600 * case match_data[2]
              when 'h' then 1
              when 'd' then 24
              when 'w' then 24*7
              else
                @logger.warn("Invalid cutoff of #{cutoff_str}")
                nil
            end
    else
      @logger.warn("Invalid cutoff of #{cutoff_str}")
      nil
    end
  end

  def valid_option?(option, given_value, valid_values)
    valid = valid_values.member?(given_value)
    @logger.warn "#{option} contained an invalid value: #{given_value}. Valid values are #{valid_values}" \
        unless valid
    valid
  end
end
