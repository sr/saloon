module CouchRest
  class Server
    attr_accessor :uri

    def initialize(uri)
      @uri = Addressable::URI.parse(uri)
    end

    # Get information about the server
    #
    # @return [Hash] Informations about the server
    def info
      get '/'
    end

    # Restarts the server
    #
    # @return [Hash] Request result
    def restart!
      post '_restart'
    end

    # Get a list of all databases available on the server
    #
    # @return [Array] List of databases
    def databases
      get '_all_dbs'
    end
  
    # Get a database
    #
    # @param [String] name Database's name
    # @return [CouchRest::Database] The database
    def database(name)
      Database.new(self, name)
    end
  
    # Create a database
    #
    # @param [String] name Database's name
    # @return [CouchRest::Database] The newly created database
    def create_db(name)
      put(name)
      database(name)
    end

    def get(path, params={})
      need_json = !params.delete(:no_json)
      response = RestClient.get(uri_for(path, params))
      need_json ? json(response, :max_nesting => false) : response
    end

    def post(path, doc=nil, params={})
      headers = params.delete(:headers)
      payload = doc.to_json if doc
      json RestClient.post(uri_for(path, params), payload, headers)
    end

    def put(path, doc=nil)
      payload = doc.to_json if doc
      json RestClient.put(uri_for(path), payload)
    end

    def delete(path)
      json RestClient.delete(uri_for(path))
    end

    private
      def uri_for(path, params={})
        uri.join(path).tap do |uri|
          uri.query_values = stringify_keys_and_jsonify_values(params) if params.any?
        end.to_s
      end

      def json(json_string, options={})
        JSON.parse(json_string, options)
      end

      def stringify_keys_and_jsonify_values(hash)
        hash.inject({}) do |memo, (key, value)|
          value = value.to_json if %w(key startkey endkey).include?(key.to_s)
          memo[key.to_s] = value.to_s
          memo
        end
      end
  end
end
