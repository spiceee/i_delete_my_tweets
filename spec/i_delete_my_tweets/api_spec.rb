require 'helper'

describe IDeleteMyTweets::Api do
  subject(:api) {
    described_class.new(config: config,
                        logger: method(:cli_stdout),
                        verbose: true,
                        a_bit: 0)
  }

  let(:config) do
    IDeleteMyTweets::Config.new(screen_name: 'spiceee',
                                older_than: 1.hour.ago,
                                fave_threshold: 0,
                                rt_threshold: 0,
                                with_words: nil)
  end

  let(:match_all_delete_req) { %r{#{Twitter::REST::Request::BASE_URL}/1\.1/statuses/destroy/([0-9]+)\.json}o }
  let(:match_all_show_req) { %r{#{Twitter::REST::Request::BASE_URL}/1\.1/statuses/show/([0-9]+)\.json}o }
  let(:fetch_statuses_uri) { "#{Twitter::REST::Request::BASE_URL}/1.1/statuses/user_timeline.json" }
  let(:stub_requests!) do
    # Stub results to be a single page for speed
    stub_request(:get, fetch_statuses_uri)
      .with(query: hash_including({screen_name: 'spiceee'}))
      .to_return(body: lambda { |req| first_page?(req) ? fixture('user_timeline.json') : [].to_json },
                 headers: {content_type: 'application/json; charset=utf-8'})

    stub_request(:post, match_all_delete_req)
      .to_return(body: fixture('status.json'),
                 headers: {content_type: 'application/json; charset=utf-8'})

    stub_request(:get, match_all_show_req)
      .to_return(body: fixture('status.json'),
                 headers: {content_type: 'application/json; charset=utf-8'})
  end

  describe '#traverse_api!' do
    before do
      stub_requests!
    end

    it 'fetches a list of tweets and deletes them' do
      capture_warning do
        api.traverse_api!
        expect(a_request(:get, fetch_statuses_uri)
            .with(query: hash_including({screen_name: 'spiceee'})))
          .to have_been_made.at_most_twice
        expect(a_request(:post, match_all_delete_req))
          .to have_been_made.times(7)
      end
    end

    describe 'with older_than criteria' do
      let(:fave_threshold) { 0 }
      let(:time_threshold) { Time.parse("Wed May 01 15:45:01 +0000 2022") }

      it 'skips tweets that are newer than older_than' do
        allow(config).to receive(:older_than).and_return(time_threshold)

        capture_warning do
          api.traverse_api!
          expect(a_request(:post, match_all_delete_req))
            .to have_been_made.once
          expect(a_request(:post, "#{Twitter::REST::Request::BASE_URL}/1.1/statuses/destroy/1521851446911807489.json"))
            .to have_been_made.once
        end
      end
    end

    describe 'with favorites criteria' do
      let(:fave_threshold) { 5 }

      it 'skips tweets that have at least 5 faves' do
        allow(config).to receive(:fave_threshold).and_return(fave_threshold)

        capture_warning do
          api.traverse_api!
          expect(a_request(:post, match_all_delete_req))
            .to have_been_made.times(6)
          expect(a_request(:post, "#{Twitter::REST::Request::BASE_URL}/1.1/statuses/destroy/1521979522148712448.json"))
            .to have_not_been_made
        end
      end

      it 'increases skipped_count by 1' do
        allow(config).to receive(:fave_threshold).and_return(fave_threshold)
        expect { api.traverse_api! }.to change(api, :skipped_count).by(1)
      end
    end

    describe 'with retweets criteria' do
      let(:rt_threshold) { 10 }

      it 'skips tweets that have at least 10 RTs' do
        allow(config).to receive(:rt_threshold).and_return(rt_threshold)

        capture_warning do
          api.traverse_api!
          expect(a_request(:post, match_all_delete_req))
            .to have_been_made.times(6)
          expect(a_request(:post, "#{Twitter::REST::Request::BASE_URL}/1.1/statuses/destroy/1521875982155763713.json"))
            .to have_not_been_made
        end
      end
    end

    describe 'with words criteria' do
      let(:rt_threshold) { 0 }
      let(:fave_threshold) { 0 }
      let(:with_words) { "#TBT, #drunktweets, trump" }
      let(:with_words2) { "bozo, FedEx" }
      let(:with_words3) { "bozo, fedex" }
      let(:with_words4) { "something, #sad" }

      it 'skips tweets that do not include the denylist' do
        allow(config).to receive(:with_words).and_return(with_words)
        allow(config).to receive(:rt_threshold).and_return(rt_threshold)
        allow(config).to receive(:fave_threshold).and_return(fave_threshold)

        capture_warning do
          api.traverse_api!
          expect(a_request(:post, match_all_delete_req))
            .to have_not_been_made
        end
      end

      it 'deletes tweets with any of the words' do
        allow(config).to receive(:with_words).and_return(with_words2)

        capture_warning do
          api.traverse_api!
          expect(a_request(:post, match_all_delete_req))
            .to have_been_made.times(2)
        end
      end

      it 'deletes tweets with any of the case variations of words' do
        allow(config).to receive(:with_words).and_return(with_words3)

        capture_warning do
          api.traverse_api!
          expect(a_request(:post, match_all_delete_req))
            .to have_been_made.times(2)
        end
      end

      it 'deletes tweets with hashtags' do
        allow(config).to receive(:with_words).and_return(with_words4)

        capture_warning do
          api.traverse_api!
          expect(a_request(:post, match_all_delete_req))
            .to have_been_made.once
        end
      end
    end

    describe 'with --dry-run' do
      it 'skips delete requests to the Twitter API' do
        allow(api).to receive(:dry_run).and_return(true)

        capture_warning do
          api.traverse_api!
          expect(a_request(:get, fetch_statuses_uri)
              .with(query: hash_including({screen_name: 'spiceee'})))
            .to have_been_made.at_most_twice
          expect(a_request(:post, match_all_delete_req))
            .to have_not_been_made
        end
      end
    end
  end

  describe '#traverse_csv!' do
    let(:csv_file_path) { File.join(fixture_path, 'tweets.csv') }

    before do
      stub_requests!
      allow(config).to receive(:path_to_csv).and_return(csv_file_path)
    end

    it 'fetches a list of tweets and deletes them' do
      capture_warning do
        api.traverse_csv!
        expect(a_request(:post, match_all_delete_req))
          .to have_been_made.times(6)
      end
    end
  end

  describe '#verify_credentials' do
    let(:stub_success_request!) do
      stub_request(:get, "#{Twitter::REST::Request::BASE_URL}/1.1/account/verify_credentials.json")
        .with(query: {skip_status: 'true'})
        .to_return(body: fixture('spiceee.json'), headers: {content_type: 'application/json; charset=utf-8'})
    end

    let(:stub_bad_request!) do
      body = "{\"code\":\"UNABLE_TO_VERIFY_CREDENTIALS\"}"
      stub_request(:get, "#{Twitter::REST::Request::BASE_URL}/1.1/account/verify_credentials.json")
        .with(query: {skip_status: 'true'})
        .to_return(status: 403, body: body, headers: {content_type: 'application/json; charset=utf-8'})
    end

    describe 'with valid credentials' do
      it "returns true" do
        stub_success_request!
        expect(api.verify_credentials).to be_truthy
      end
    end

    describe 'with invalid credentials' do
      it "returns true" do
        stub_bad_request!
        expect(api.verify_credentials).to be_falsey
      end
    end
  end
end

def first_page?(req)
  !req.uri.to_s.include?("max_id")
end
