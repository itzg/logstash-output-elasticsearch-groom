require 'elasticsearch'

module LogStash::Outputs::EsGroom

  class EsAccessor
    def initialize(options={})
      @client = Elasticsearch::Client.new host: options[:host]
    end

    # Identifies indices that match a given `pattern`
    # @option arguments [String] :pattern An index pattern to use for finding matches
    # @option arguments [String] :scope Specifies if 'open', 'closed', or 'both' index states should be considered
    public
    def matching_indices(options={})
      options = {
          scope: 'open'
      }.merge(options)

      # Need to emulate 'both'
      resolvedScope = options[:scope] == 'both' ? %w(open closed) : options[:scope]

      fullResults = @client.indices.get index: options[:pattern], expand_wildcards: resolvedScope
      return fullResults.keys
    end
  end

end