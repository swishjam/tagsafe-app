class Util
  class << self
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