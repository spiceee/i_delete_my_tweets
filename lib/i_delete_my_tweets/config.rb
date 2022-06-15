require 'thor'

module IDeleteMyTweets
  CONFIG_VARS = [
    "CONSUMER_KEY",
    "CONSUMER_SECRET",
    "ACCESS_TOKEN",
    "ACCESS_TOKEN_SECRET",
    "OLDER_THAN",
    "PATH_TO_CSV",
    "FAVE_THRESHOLD",
    "RT_THRESHOLD",
    "WITH_WORDS",
    "SCREEN_NAME"
  ].freeze
  PATH_TO_ENV = "~/.i_delete_my_tweets".freeze
  OBFUSCATE_WORDS = %w(secret token key).freeze
  OPTIONALS = %w(with_words).freeze

  class Config
    attr_accessor :consumer_key,
                  :consumer_secret,
                  :access_token,
                  :access_token_secret,
                  :older_than,
                  :path_to_csv,
                  :fave_threshold,
                  :rt_threshold,
                  :with_words,
                  :screen_name

    def initialize(opts = {})
      @consumer_key = opts[:consumer_key] || ENV.fetch("CONSUMER_KEY", nil)
      @consumer_secret = opts[:consumer_secret] || ENV.fetch("CONSUMER_SECRET", nil)
      @access_token = opts[:access_token] || ENV.fetch("ACCESS_TOKEN", nil)
      @access_token_secret = opts[:access_token_secret] || ENV.fetch("ACCESS_TOKEN_SECRET", nil)
      @older_than = opts[:older_than] || Time.parse(ENV.fetch("OLDER_THAN", 1.week.ago).to_s)
      @path_to_csv = opts[:path_to_csv] || ENV.fetch("PATH_TO_CSV", "./")
      @fave_threshold = opts[:fave_threshold] || ENV.fetch("FAVE_THRESHOLD", 0)
      @rt_threshold = opts[:rt_threshold] || ENV.fetch("RT_THRESHOLD", 0)
      @with_words = opts[:with_words] || ENV.fetch("WITH_WORDS", "")
      @screen_name = opts[:screen_name] || ENV.fetch("SCREEN_NAME", "")
    end

    def zipped
      values = CONFIG_VARS.map do |k|
        normalized_key = k.downcase
        value = send(normalized_key.to_sym)
        OBFUSCATE_WORDS.any? { |word| normalized_key.include?(word) } ? obfuscate_token(value) : value
      end
      CONFIG_VARS.zip(values)
    end

    def to_table
      Terminal::Table.new do |table|
        table.title = "[I Delete My Tweets] Configuration"
        table.headings = ["KEY", "VALUE"]
        table.rows = zipped
        table.style = Presenter::TABLE_STYLE
      end
    end

    def to_env
      CONFIG_VARS.map { |k| "#{k}='#{send(k.downcase.to_sym).to_s.gsub("'"){ "\\'" }}'" }
      # ^ Escaping with single quotes because some shells are not nice with ruby unquoted timestamps
    end

    def empty_values
      zipped.reject{ |tuples| OPTIONALS.member?(tuples.first.downcase) }
            .map { |tuples| tuples.second.to_s.empty? ? tuples.first : nil }
            .compact
    end

    def compiled_words_regex
      @compiled_words_regex ||= Regexp.union(with_words.split(",").map(&:squish).map { |w| /^#{Regexp.quote(w)}$/i })
    end

  private

    def obfuscate_token(token)
      return if token.nil?

      token.size > 3 ? token.gsub(/^.+(.{3,})$/m, '*********************\1') : "***"
    end
  end
end
