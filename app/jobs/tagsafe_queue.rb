class TagsafeQueue
  class << self
    %i[critical normal low].each do |queue|
      define_method(queue.upcase) { queue }
    end
  end
end