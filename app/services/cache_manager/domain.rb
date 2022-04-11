module CacheManager
  class Domain
    def initialize(domain)
      @domain = domain
    end

    def update_cache!
      Rails.cache.write("domain_#{@domain.id}", domain_cache)
    end

    private

    def domain_cache
      
    end
  end
end