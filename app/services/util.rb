class Util
  class << self
    def env_is_true?(env)
      ENV[env] == 'true' || ENV[env] == true
    end
    alias env_is_true env_is_true?

    def integer_to_interval_in_words(minutes)
      case minutes.to_i
      when 0 then 'disabled'
      when 1 then 'every minute'
      when 2..59 then "every #{minutes} minutes"
      when 60 then "every hour"
      when 60..1_439 then "every #{minutes.to_i / 60} hours"
      when 1_440 then 'once a day'
      end
    end

    def minutes_to_words(minutes)
      case minutes.to_i
      when 1 then "1 minute"
      when 2..59 then "#{minutes_left} minutes"
      when 60..89 then "1 hour"
      when 90..1_440 then "#{(minutes/60.0).round} hours"
      else  
        "#{(minutes / 1_440.0).round} days"
      end
    end

    def create_dir_if_neccessary(*directories)
      directories.count.times{ |i| Dir.mkdir(directories[0..i].join('/')) unless Dir.exist? directories[0..i].join('/') }
      directories.join('/')
    end

    def domain_url_without_subdomain(url)
      hostname = URI.parse(url).hostname
      hostname
    end
  end
end