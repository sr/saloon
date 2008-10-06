require 'cgi'
require 'base64'

module CouchRest
  class Database
    attr_accessor :server, :name

    def initialize(server, database_name)
      @name = database_name
      @server = server
    end
    
    # Get a list of documents available in the database
    #
    # @param [Hash] params
    def documents(params={})
      server.get("#{name}/_all_docs", params)
    end
  
    # Creates a temporary view
    #
    # @param [String] function The view function
    # @param [Hash] params
    def temp_view(function, params={})
      server.post("#{name}/_temp_view", function,
        params.merge!(:headers => {'Content-Type' => 'application/json'}))
    end
  
    # Query the given view
    #
    # @param [String] view_name The name of the view
    # @param [Hash] params
    def view(view_name, params={})
      server.get("#{name}/_view/#{view_name}", params)
    end

    # Retrieve a document by its ID
    #
    # @param [String] id The ID of the document
    def get(id)
      server.get("#{name}/#{CGI.escape(id)}")
    end
    
    # Retrieve an attachment from a document
    #
    # @param [String] document_id The ID of the document
    # @param [String] attachment_name The name of the attachment
    def fetch_attachment(document_id, attachment_name)
      server.get("#{name}/#{CGI.escape(document_id)}/#{CGI.escape(attachment_name)}", :no_json => true)
    end
    
    # Save or update a document
    #
    # @param [Hash] doc The document
    def save(doc)
      doc['_attachments'] = encode_attachments(doc['_attachments']) if doc['_attachments']

      if doc['_id']
        server.put("#{name}/#{CGI.escape(doc['_id'])}", doc)
      else
        server.post("#{name}", doc)
      end
    end
    
    # Save or update multiple documents
    #
    # @param [Array] docs The documents
    def bulk_save(docs)
      server.post("#{name}/_bulk_docs", {:docs => docs})
    end
    
    # Delete a document
    #
    # @param [String, Hash] doc Document ID or a document
    # @raise ArgumentError
    def delete(doc)
      case doc
      when String
        server.delete "#{name}/#{CGI.escape(doc)}"
      when Hash
        raise ArgumentError unless doc['_id']
        path = "#{name}/#{CGI.escape(doc['_id'])}"
        path << "?rev=#{doc['_rev']}" if doc['_rev']
        server.delete path
      else
        raise ArgumentError
      end
    end
    
    # Delete the database
    def delete!
      server.delete(name)
    end

    private
      def encode_attachments(attachments)
        attachments.each do |k, v|
          next if v['stub']
          v['data'] = base64(v['data'])
        end
        attachments
      end

      def base64(data)
        Base64.encode64(data).gsub(/\s/,'')
      end
  end
end
