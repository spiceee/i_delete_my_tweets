require 'semver'

module IDeleteMyTweets
  module Version
  module_function

    def parsed_version
      @parsed_version ||= SemVer.find
    end

    # @return [Integer]
    def major
      parsed_version.major
    end

    # @return [Integer]
    def minor
      parsed_version.minor
    end

    # @return [Integer]
    def patch
      parsed_version.patch
    end

    # @return [Integer, NilClass]
    def pre
      parsed_version.prerelease.empty? ? nil : parsed_version.prerelease
    end

    # @return [Hash]
    def to_h
      {
        major: major,
        minor: minor,
        patch: patch,
        pre: pre,
      }
    end

    # @return [Array]
    def to_a
      [major, minor, patch, pre].compact
    end

    # @return [String]
    def to_s
      to_a.join('.')
    end
  end

  module Description
  module_function

    def to_s
      <<~'DESCRIPTION'
        A CLI (as in Command Line Interface) to delete your tweets based on faves, RTs, and time.

        There are some services out there with a friendly web interface, but this is not one of them. You must know the basics of working with a UNIX terminal and configuring a Twitter API app, as this will only work if you have a Twitter Developer account.

        Due to the irrevocable nature of tweet deletion, all delete commands are dry-run true, meaning you must call all of them with a --dry-run=false flag if you want them to really do something.

        Called with --dry-run=false, there is no way to revoke tweet deletion. They are just gone, disappeared into the ether (or the stashed in the Twitter-owned secret place you have no access to without a mandate since nothing gets really deleted from the web these days, folks).

        This tool won't delete all of your tweets in one fell swoop; it is more of a way to delete your old tweets from time to time. The Twitter API rate limits are relatively complicated, and I don't even wanna go there, but if you do intend on deleting all of your tweets, you can do it with this CLI and some perseverance. I did delete more than 100k of mine by using this script every day for a couple of weeks. The more tweets you delete, the fewer of them you have, and with time the rate limits won't be that much of a problem.

        I Delete My Tweets (IDMT) can delete your tweets by fetching them via API using an APP you will have to set up yourself. Still, it can also delete tweets from an CSV (comma-separated file) that you can generate from the archive you can request from twitter.com by going to Settings and privacy > Your Account > Download an archive of your data. It is out of the scope of this CLI to generate the CSV (at the moment) but there are scripts out there that can do this for you.
      DESCRIPTION
    end
  end
end
