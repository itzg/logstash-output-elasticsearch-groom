require 'elasticsearch'

module LogStash::Outputs::EsGroom

  # Abstracts the connectivity to Elasticsearch and the ES specific operations.
  class EsAccessor
    def initialize(options={})
      @client = Elasticsearch::Client.new host: options[:host]
    end

    public
    def close_indices(indices)
      return if indices.empty?

      # close doesn't accept a list, so iterate to pull it off
      indices.each do |i|
        @client.indices.close index: i
      end
    end

    public
    def delete_indices(indices)
      return if indices.empty?
      @client.indices.delete index: indices
    end

    public
    def matching_indices(pattern='_all', scope='open')

      # Need to emulate 'both'
      resolved_scope = scope == 'both' ? %w(open closed) : scope

      begin
        full_results = @client.indices.get index: pattern, expand_wildcards: resolved_scope
        full_results.keys
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        # This gets raised when no indices match the given pattern
        return []
      end
    end
  end

end