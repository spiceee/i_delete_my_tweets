require 'ostruct'

module IDeleteMyTweets
  class Api
    include Presenter
    attr_reader :config, :verbose, :log, :dry_run, :a_bit
    attr_accessor :delete_count, :skipped_count, :not_found_count

    def initialize(opts = {})
      @config = opts[:config] || Config.new
      @verbose, @log, @dry_run = opts[:verbose], opts[:logger], opts[:dry_run]
      @delete_count, @skipped_count, @not_found_count = 0, 0, 0
      @a_bit = opts[:a_bit] || 5
    end

    def traverse_api!
      all_tweets.each do |tweet|
        if can_be_destroyed?(tweet)
          destroy_with_retry(tweet)
          sleep a_bit
        else
          self.skipped_count += 1
        end
      end
    rescue IOError
      do_log(" 💥 Oops, there was a connection error! ", color: :red)
    ensure
      do_log summary delete_count, skipped_count, not_found_count, dry_run
    end

    def traverse_csv!
      CSV.foreach(config.path_to_csv, headers: true) do |row|
        tweet = csv_row_to_struct(row)
        if can_be_destroyed?(tweet)
          destroy_with_retry(tweet)
          sleep a_bit
        else
          self.skipped_count += 1
        end
      end
    rescue IOError
      do_log(" 💥 Oops, there was a connection error! ", color: :red)
    ensure
      do_log summary delete_count, skipped_count, not_found_count, dry_run
    end

    def client
      @client ||= Twitter::REST::Client.new do |c|
        c.consumer_key = config.consumer_key
        c.consumer_secret = config.consumer_secret
        c.access_token = config.access_token
        c.access_token_secret = config.access_token_secret
      end
    end

    def verify_credentials
      client.verify_credentials(skip_status: true)
      do_log(" 🎉 We could verify your ❝#{config.screen_name}❞ credentials with Twitter and it looks good! ", color: :white, force_new_line: false)
      true
    rescue Twitter::Error => e
      if e.is_a?(Twitter::Error::Forbidden)
        do_log(" 🚫 Oops, Twitter cannot verify the crendentials for #{config.screen_name} ", color: :red)
      else
        do_log(" 🚫 Oops, something bad happened: #{e.message} ", color: :red)
      end
      false
    end

  private

    def destroy_with_retry(tweet)
      destroy_tweet!(tweet.id)
    rescue HTTP::ConnectionError
      do_log "💥 == trying again =="
      destroy_tweet!(tweet.id)
    rescue Twitter::Error::TooManyRequests => e
      do_log "💥 == we've reached a rate limit, sleeping it off =="
      sleep e.rate_limit.reset_in + 1
      retry
    ensure
      do_log tweet_presenter(tweet, dry_run, verbose: verbose), force_new_line: verbose
    end

    def destroy_tweet!(id)
      client.destroy_status(id) unless dry_run
      self.delete_count += 1
    end

    def do_log(message, color: nil, force_new_line: true)
      log&.call("", nil, true) if force_new_line
      log&.call(message, color || COLORS.sample, force_new_line)
    end

    def fetch_tweet(id)
      client.status(id)
    rescue Twitter::Error::NotFound
      do_log tweet_not_found(id, dry_run, verbose: verbose)
      self.not_found_count += 1
      nil
    end

    def satisfies_older_than?(tweet)
      tweet.created_at < config.older_than
    end

    def bellow_fave_threshold?(tweet)
      return true if config.fave_threshold.to_i == 0
      return true unless tweet.favorite_count > 0

      tweet.favorite_count < config.fave_threshold.to_i
    end

    def bellow_rt_threshold?(tweet)
      return true if config.rt_threshold.to_i == 0
      return true unless tweet.retweet_count > 0

      tweet.retweet_count < config.rt_threshold.to_i
    end

    def includes_words?(tweet)
      tweet.text.match(config.compiled_words_regex)
    end

    def can_be_destroyed?(tweet)
      return false unless satisfies_older_than? tweet

      if config.with_words.empty?
        return false unless bellow_fave_threshold? tweet
        return false unless bellow_rt_threshold? tweet

        true
      else
        includes_words?(tweet)
      end
    end

    def collect_with_max_id(collection = [], max_id = nil, &block)
      response = yield(max_id)
      collection += response
      response.empty? ? collection.flatten : collect_with_max_id(collection, response.last.id - 1, &block)
    end

    def all_tweets
      @all_tweets ||= collect_with_max_id do |max_id|
        options = {count: 200, include_rts: true}
        options[:max_id] = max_id unless max_id.nil?
        client.user_timeline(config.screen_name, options)
      end
    rescue HTTP::ConnectionError
      do_log(" 💥 Oops, there was a connection error fetching your tweets! ", color: :red)
    end

    def csv_row_to_struct(row)
      Struct.new(:id, :favorite_count,
                 :retweet_count, :created_at,
                 :text, keyword_init: true).new(id: row["tweet_id"],
                                                text: row["text"],
                                                created_at: to_date(row["created_at"]),
                                                favorite_count: row["favorite_count"],
                                                retweet_count: row["retweet_count"])
    end
  end
end
