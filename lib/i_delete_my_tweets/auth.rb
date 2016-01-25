require "oauth"

module IDeleteMyTweets
  module Auth
    def consumer(client)
      OAuth::Consumer.new(
        client.consumer_key,
        client.consumer_secret,
        site: Twitter::REST::Request::BASE_URL,
      )
    end

    def pin_auth_parameters
      {oauth_callback: "oob"}
    end

    def get_request_token(client)
      consumer(client).get_request_token
    rescue StandardError => e
      say_error set_color " 🚫 Oops, something bad happened: #{e.message} ", :white, :on_red, :bold
    end

    def get_access_credentials(request_token, pin)
      access_token = request_token.get_access_token(oauth_verifier: pin.chomp)
      {oauth_token: access_token.token,
       oauth_token_secret: access_token.secret,
       screen_name: access_token.params[:screen_name]}
    rescue StandardError => e
      say_error set_color " 🚫 Oops, something bad happened: #{e.message} ", :white, :on_red, :bold
    end

    def generate_authorize_url(client, request_token)
      oauth = consumer(client)
      request = oauth.create_signed_request(:get, oauth.authorize_path, request_token, pin_auth_parameters)
      build_path(request, build_headers(request))
    end

    def build_path(request, params)
      "#{Twitter::REST::Request::BASE_URL}#{request.path}?#{params}"
    end

    def build_headers(request)
      request["Authorization"].sub(/^OAuth\s+/, "").split(/,\s+/).map { |p|
        k, v = p.split("=")
        v =~ /"(.*?)"/
        "#{k}=#{CGI.escape($1)}"
      }.join("&")
    end
  end
end
