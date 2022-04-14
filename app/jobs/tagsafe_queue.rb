class TagsafeQueue
  class << self
    %i[lambda_results critical normal low].each do |queue|
      define_method(queue.upcase) { queue }
    end
  end
end