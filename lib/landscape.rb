%w[ base64 cgi openssl digest/sha1 net/https net/http time ostruct json].each { |f| require f }

module Landscape
  # Generate the canonical string for signing requests. 
  # This strips out all '&', '?', and '=' from the query string to be signed.
  # The parameters in the path passed in must already be sorted in 
  # case-insensitive alphabetical order and must not be url encoded.
  #
  # @param [String] params the params that will be sorted and encoded as a canonical string.
  # @param [String] host the hostname of the API endpoint.
  # @param [String] method the HTTP method that will be used to submit the params.
  # @param [String] base the URI path that this information will be submitted to.
  # @return [String] the canonical request description string.
  def Landscape.canonical_string(params, method="POST", uri)
    # Sort, and encode parameters into a canonical string.
    sorted_params = params.sort {|x,y| x[0] <=> y[0]}
    encoded_params = sorted_params.collect do |p| 
      encoded = (CGI::escape(p[0].to_s) +
                 "=" + CGI::escape(p[1].to_s))
      # Ensure spaces are encoded as '%20', not '+'
      encoded = encoded.gsub('+', '%20')
      # According to RFC3986 (the scheme for values expected by signing requests), '~'·
      # should not be encoded
      encoded = encoded.gsub('%7E', '~')
    end 
    sigquery = encoded_params.join("&")

    # Generate the signing string
    method + "\n" + uri.host + "\n" + uri.path + "\n" + sigquery
  end

  # Encodes the given string with the secret_access_key by taking the
  # hmac-sha1 sum, and then base64 encoding it.  Optionally, it will also
  # url encode the result of that to protect the string if it's going to
  # be used as a query string parameter.
  #
  # @param [String] secret_access_key the user's secret access key for signing.
  # @param [String] str the string to be hashed and encoded.
  # @param [Boolean] urlencode whether or not to url encode the result., true or false
  # @return [String] the signed and encoded string.
  def Landscape.encode(secret_access_key, str, urlencode=true)
    digest = OpenSSL::Digest::Digest.new('sha256')
    b64_hmac =
      Base64.encode64(
        OpenSSL::HMAC.digest(digest, secret_access_key, str)).gsub("\n","")

    if urlencode
      return CGI::escape(b64_hmac)
    else
      return b64_hmac
    end
  end

  # pathlist is a utility method which takes a key string and and array as input.
  # It converts the array into a Hash with the hash key being 'Key.n' where
  # 'n' increments by 1 for each iteration.  So if you pass in args
  # ("tags", ["web", "server"]) you should get
  # {"tags.1"=>"web", "tags.2"=>"server"} returned.
  # @param [String] key The name for the keys
  # @param [Array] arr The list of elements to be keyed using the key
  def Landscape.pathlist(key, arr)
    params = {}
    arr.each_with_index do |value, i|
      params["#{key}.#{i+1}"] = value
    end
    params
  end

  class Client
    # @option options [String] :api_access_key ("") The user's Landscape Access Key ID
    # @option options [String] :secret_access_key ("") The user's Landscape Secret Access Key
    # @option options [String] :endpoint ("https://landscape.canonical.com/api/")
    # @return [Object] the object.
    def initialize(options = {})
      options = {endpoint: 'https://landscape.canonical.com/api/',
                 api_access_key: '',
                 secret_access_key: '',
                 version: '2011-08-01'}.merge(options)

      @endpoint = URI(options[:endpoint])
      @version = options[:version]
      raise ArgumentError, 'No :api_access_key provided' if options[:api_access_key].nil? || options[:api_access_key].empty?
      raise ArgumentError, 'No :secret_access_key provided' if options[:secret_access_key].nil? || options[:secret_access_key].empty?
      @api_access_key = options[:api_access_key]
      @secret_access_key = options[:secret_access_key]
    end

    def endpoint
      @endpoint.to_s
    end

    # Make the HTTP request to Landscape.
    # @param [String] action the named action to request of the Landscape server e.g. GetComputers
    # @param [Hash] params the list of additional parameters for the action
    def make_request(action, params)
      Net::HTTP.start(@endpoint.host, @endpoint.port, use_ssl: @endpoint.scheme == 'https', set_debug_output: $stderr) do |http|
        # Strip out empty or nil values
        params.reject! { |key, value| value.nil? or value.empty?}

        params.merge!({'action' => action,
                       'signature_version' => '2',
                       'signature_method' => 'HmacSHA256',
                       'access_key_id' => @api_access_key,
                       'version' => @version,
                       'timestamp' => Time.now.getutc.iso8601})

        sig = get_landscape_auth_param(params, @secret_access_key, @endpoint.host)
        query = params.sort.collect do |param|
          CGI::escape(param[0]) + "=" + CGI::escape(param[1])
        end.join("&") + "&signature=" + sig

        req = Net::HTTP::Post.new(@endpoint.path)
        req.content_type = 'application/x-www-form-urlencoded'
        req['User-Agent'] = "landscape-api-ruby-gem"
        response = http.request(req, query)
        response
      end
    end

    # Set the Authorization header using Landscape signed header authentication
    def get_landscape_auth_param(params, secret_access_key, server)
      canonical_string =  Landscape.canonical_string(params, "POST", @endpoint)
      encoded_canonical = Landscape.encode(secret_access_key, canonical_string)
    end

    # This is the main method in the client for API calls to call
    # @option options [String] :action ("") The API method to call.
    # @option options [Hash] :params List of parameters for the API call.
    def fetch_response( options = {} )
      options = {
        :action => "",
        :params => {}
      }.merge(options)

      raise ArgumentError, ":action must be provided to fetch_response" if options[:action].nil? || options[:action].empty?
      http_response = make_request(options[:action], options[:params])  
      landscape_error?(http_response)
      return http_response.body
    end

  protected

    # Raises the appropriate error if the specified Net::HTTPResponse object
    # contains a Landscape error; returns false otherwise.
    def landscape_error?(response)
      # return false if we got a HTTP 200 code,
      # otherwise there is some type of error (40x,50x) and
      # we should try to raise an appropriate exception
      # from one of our exception classes defined in
      # errors.rb
      return false if response.is_a?(Net::HTTPSuccess)

      raise Landscape::Error, "Unexpected server error. response.body is: #{response.body}" if response.is_a?(Net::HTTPServerError)
      error_message = JSON.parse(response.body)
      # Raise one of our specific error classes if it exists.
      # otherwise, throw a generic Error with a few details.
      if Landscape::Errors.const_defined?(error_message['error'])
        raise Landscape::Errors.const_get(error_message['error']), error_message['message']
      else
        raise Landscape::Errors::Error, error_message['message']
      end
    end
  end

end

Dir[File.join(File.dirname(__FILE__), 'landscape/**/*.rb')].sort.each { |lib| require lib }
