describe IDeleteMyTweets::CommandConfig do
  subject(:cli) {
    described_class.new
  }

  describe "#check" do
    it "returns config is ok" do
      stub_request(:get, "#{Twitter::REST::Request::BASE_URL}/1.1/account/verify_credentials.json")
        .with(query: {skip_status: 'true'})
        .to_return(body: fixture('spiceee.json'), headers: {content_type: 'application/json; charset=utf-8'})
      expect { cli.check }.to output(/all set!/).to_stdout
    end

    it "returns config is broken" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('SCREEN_NAME', '').and_return(nil)
      expect { cli.check }.to output(/SCREEN_NAME/).to_stderr
    end
  end

  describe "#store" do
    before do
      allow_any_instance_of(described_class).to receive(:create_file).and_return(true)
      allow_any_instance_of(described_class).to receive(:comment_lines).and_return(true)
      allow_any_instance_of(described_class).to receive(:insert_into_file).and_return(true)
    end

    it "stores a key value pair in .env" do
      expect(cli.store('SCREEN_NAME', 'foobar')).to be(true)
    end

    describe "with --dry-run=false" do
      it "updates value in config" do
        allow(File).to receive(:expand_path).and_return("./a_file")
        allow(File).to receive(:exist?).and_return(true)

        cli.invoke "store", ['SCREEN_NAME', 'foobar'], dry_run: false
        expect(File).to have_received(:expand_path).at_least(:once)
        expect(File).to have_received(:exist?).at_least(:once)
      end
    end

    describe "#authorize_with_pin" do
      let(:config) {
        instance_double(IDeleteMyTweets::Config)
      }
      let(:oauth) {
        instance_double(OAuth::Consumer, get_request_token: "a-token")
      }
      let(:oauth_token) { "fofofofofoofofof" }
      let(:oauth_token_secret) { "eleklekelkelkelkele" }
      let(:screen_name) { "supertweeter" }

      before do
        allow(described_class).to receive(:cli_config).and_return(config)
        allow_any_instance_of(described_class).to receive(:get_request_token).and_return(oauth)
        allow_any_instance_of(described_class).to receive(:generate_authorize_url).and_return("http://example.com")
        allow_any_instance_of(described_class).to receive(:get_access_credentials).and_return( {oauth_token: oauth_token,
                                                                                                oauth_token_secret: oauth_token_secret,
                                                                                                screen_name: screen_name})
        allow_any_instance_of(described_class).to receive(:create_file).and_return(true)
        allow_any_instance_of(described_class).to receive(:comment_lines).and_return(true)
        allow_any_instance_of(described_class).to receive(:insert_into_file).and_return(true)
      end

      describe "with --dry-run=true" do
        it "returns updated table with new values" do
          allow(Thor::LineEditor).to receive(:readline).and_return("11223344")
          expect { cli.invoke "authorize_with_pin", ['a-token', 'a-secret-token'], dry_run: true }.to output(/supertweeter/).to_stdout
        end
      end

      describe "with --dry-run=false" do
        it "updates value in config" do
          allow(Thor::LineEditor).to receive(:readline).and_return("11223344")
          allow(File).to receive(:expand_path).and_return("./a_file")
          allow(File).to receive(:exist?).and_return(true)

          cli.invoke "authorize_with_pin", ['a-token', 'a-secret-token']
          expect(File).to have_received(:expand_path).at_least(:once)
          expect(File).to have_received(:exist?).at_least(:once)
        end
      end
    end

    describe "with --dry-run=true" do
      it "returns updated table with new value" do
        expect { cli.invoke "store", ['SCREEN_NAME', 'foobar'], dry_run: true }.to output(/foobar/).to_stdout
      end
    end
  end
end
