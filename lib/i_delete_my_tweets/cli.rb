require 'thor'

module IDeleteMyTweets
  class CommandConvert < Thor
    class_option :dry_run, type: :boolean, default: true
    KEYS = %w(id retweet_count favorite_count created_at full_text).freeze
    HEADERS = %w(tweet_id retweet_count favorite_count created_at text).freeze

    desc "to_csv", "Converts the tweet.js archive to csv"
    def to_csv(path_to_tweets_js)
      `sed -i"" -e "s/window.YTD.tweet.part0 = //g" #{path_to_tweets_js}`
      if $?.success?
        save_to_csv(path_to_tweets_js)
        say set_color "Success: #{path_to_tweets_js} was converted to converted_tweets_js.csv!", :green, :bold
      end
    rescue StandardError => e
      say_error e.message
    end

  private

    def save_to_csv(path_to_tweets_js)
      CSV.open("converted_tweets_js.csv", "w") do |csv|
        csv << HEADERS
        JSON.parse(File.read(path_to_tweets_js)).each do |hash|
          csv << hash["tweet"].fetch_values(*KEYS)
        end
      end
    end
  end

  class CommandDelete < Thor
    class_option :dry_run, type: :boolean, default: true

    include Ascii
    desc "start", "Starts the deleting process"
    def start
      say show_face, :yellow if options[:verbose]
      say set_color api.config.to_table, :green, :bold
      api.traverse_api!
    end

    desc "from_csv", "Starts the deleting process using a csv file"
    def from_csv
      say show_face, :yellow if options[:verbose]
      say set_color api.config.to_table, :green, :bold
      api.traverse_csv!
    end

  private

    def api
      @api ||= IDeleteMyTweets::Api.new(verbose: options[:verbose], logger: method(:say), dry_run: options[:dry_run])
    end
  end

  class CommandConfig < Thor
    include Thor::Actions
    include Auth
    class_option :dry_run, type: :boolean, default: false

    desc "check", "Checks if the configuration is ok"
    def check
      bad_configs = cli_config.empty_values

      if bad_configs.empty?
        api = IDeleteMyTweets::Api.new(logger: method(:say))
        api.verify_credentials
        say set_color " ✅ You're all set! ", :white, :on_green, :bold
        say set_color cli_config.to_table, :green
      else
        say_error set_color " 🚫 Oops, #{bad_configs.join(', ')} #{bad_configs.size == 1 ? 'is' : 'are'} missing! ", :white, :on_red, :bold
      end
    end

    desc "store <key> <value>", "Stores the configuration <key> with value <value>"
    def store(key, value)
      raise Error, "ERROR: #{key} does not exist" unless CONFIG_VARS.include?(key.strip)

      conf = cli_config
      conf.send("#{key.downcase.to_sym}=", value);

      if options[:dry_run]
        say set_color conf.to_table, :green, :bold
      else
        dump_to_file!(conf)
      end
    end

    desc "authorize_with_pin <consumer-key> <consumer-secret>", "Generates a URL to auth the app"
    map %w[-a --authorize-with-pin] => :authorize_with_pin
    def authorize_with_pin(consumer_key, consumer_secret)
      conf = cli_config
      conf.consumer_key, conf.consumer_secret = consumer_key, consumer_secret
      api = IDeleteMyTweets::Api.new(config: conf)

      request_token = get_request_token(api.client)
      auth_url = generate_authorize_url(api.client, request_token)

      pin = ask set_color interactive_pin_message(auth_url), :green, :bold
      credentials = get_access_credentials(request_token, pin)
      update_and_rewrite_conf!(conf, credentials)
    end

  private

    def update_and_rewrite_conf!(config, new_creds)
      config.access_token, config.access_token_secret = new_creds[:oauth_token], new_creds[:oauth_token_secret]
      config.screen_name = new_creds[:screen_name]

      if options[:dry_run]
        say set_color config.to_table, :green, :bold
      else
        dump_to_file!(config)
      end
    end

    def interactive_pin_message(auth_url)
      <<~MESSAGE
        👋 Open this URL in a browser, preferably the one you're logged into the
        Twitter account you want to delete tweets from:

        ✂️------------------------------------------------------------------

        #{auth_url}

        ------------------------------------------------------------------✂️

        Then copy and paste below the PIN you'll receive once you've authorized the
        Twitter app you've set up for this ⬇️
      MESSAGE
    end

    def dump_to_file!(conf)
      path = File.expand_path(PATH_TO_ENV)
      File.exist?(path) ? comment_lines(path, /^[A-Z]/) : create_file(PATH_TO_ENV)

      insert_into_file(path) { ["\n", conf.to_env].join("\n") }
    end

    def cli_config
      @cli_config ||= IDeleteMyTweets::Config.new
    end
  end

  class CLI < Thor
    check_unknown_options!
    class_option :verbose, type: :boolean, default: true

    def self.exit_on_failure?
      true
    end

    desc "version", "Displays version"
    map %w[-v --version] => :version
    def version
      say Gem.loaded_specs["i_delete_my_tweets"]&.version || Version
    end

    desc "delete command ...ARGS", "Deletes your tweets based on time, faves and RTs"
    subcommand "delete", CommandDelete

    desc "config command ...ARGS", "Configures the Twitter app credentials"
    subcommand "config", CommandConfig

    desc "convert command ...ARGS", "Converts the tweets.js archive to CSV"
    subcommand "convert", CommandConvert
  end
end
