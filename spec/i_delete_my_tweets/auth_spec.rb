require 'helper'

describe IDeleteMyTweets::Auth do
  subject(:dummy) {
    stub_const("IDeleteMyTweets::Authee", dummy_class, transfer_nested_constants: true).new
  }

  let(:dummy_class) { Class.new { include IDeleteMyTweets::Auth } }
  let(:client) { instance_double(IDeleteMyTweets::Config, consumer_key: "foo", consumer_secret: "bar") }
  let(:access_token) { stub_const("Token", dummy_class) }
  let(:oauth) do
    instance_double(OAuth::Consumer, get_request_token: "a-token", get_access_token: access_token)
  end
  let(:request) { instance_double(Net::HTTP::Get, consumer_key: "foo", consumer_secret: "bar") }
  let(:auth_header) do
    <<~AUTH
      OAuth oauth_callback="oob", oauth_consumer_key="12345", oauth_nonce="12345", oauth_signature="12345", oauth_signature_method="HMAC-SHA1", oauth_timestamp="12345", oauth_token="12345", oauth_version="1.0"
    AUTH
  end

  before do
    allow(oauth).to receive(:create_signed_request).and_return({"Authorization" => auth_header})
    allow(oauth).to receive(:authorize_path).and_return("/authorize")
    allow(dummy).to receive(:consumer).and_return(oauth)
    allow(dummy).to receive(:build_path).and_return("http://example.com/auth/authorize")
    allow(access_token).to receive(:token).and_return("another-token")
    allow(access_token).to receive(:secret).and_return("a big secret")
    allow(access_token).to receive(:params).and_return({screen_name: "atwitteruser"})
  end

  describe '#pin_auth_parameters' do
    it "returns a hash of options with :oauth_callback" do
      expect(dummy.pin_auth_parameters).to include(oauth_callback: 'oob')
    end
  end

  describe '#get_request_token' do
    it "returns an access_token" do
      expect(dummy.get_request_token(client)).to eq("a-token")
    end
  end

  describe '#get_access_credentials' do
    it "returns a hash with user data" do
      expect(dummy.get_access_credentials(oauth, "pin")).to include(:oauth_token, :oauth_token_secret, :screen_name)
    end
  end

  describe '#generate_authorize_url' do
    it "returns an url to generate a pin" do
      expect(dummy.generate_authorize_url(client, "a-token")).to match("/auth/authorize")
    end
  end
end
