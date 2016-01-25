module IDeleteMyTweets
  module Presenter
    COLORS = [
      :red,
      :green,
      :yellow,
      :blue,
      :magenta,
      :cyan
    ].freeze

    TABLE_STYLE = {border: Terminal::Table::UnicodeRoundBorder.new}.freeze

    def summary(delete_count, skipped_count, not_found_count, dry_run)
      Terminal::Table.new do |table|
        table.title = "Summary"
        table.headings = ["Deleted", "Skipped", "Not Found", "Dry Run?"]
        table.rows = [[delete_count, skipped_count, not_found_count, dry_run.present?]]
        table.style = TABLE_STYLE
      end
    end

    def tweet_presenter(tweet, dry_run, verbose: true)
      if verbose
        Terminal::Table.new do |table|
          table.title = "🐤 Deleted Tweet 🚽"
          table.headings = ["Text", "Date", "Faves", "RTs", "Dry Run?"]
          table.rows = [[truncate(tweet.text), to_human_time(tweet.created_at), tweet.favorite_count, tweet.retweet_count, dry_run.present?]]
          table.style = TABLE_STYLE
        end
      else
        ".🐤 "
      end
    end

    def tweet_not_found(tweet_id, dry_run, verbose: true)
      if verbose
        Terminal::Table.new do |table|
          table.title = "💥 Tweet Not Found 💥"
          table.headings = ["ID", "Dry Run?"]
          table.rows = [[tweet_id, dry_run.present?]]
          table.style = TABLE_STYLE
        end
      else
        ".💥 "
      end
    end

    def truncate(text)
      text.gsub(/^(.{40,}?).*$/m, '\1...')
    end

    def to_time(timestamp)
      Date.parse timestamp
    end

    def to_human_time(time)
      time.strftime("%Y-%m-%d %H:%M")
    end
  end
end
