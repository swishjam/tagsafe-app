class TagsafeOptimizationsEstimator
  def self.estimate_optimizations_for(page_url)
    json = {}
    page_url.page_loads.group_by(&:num_tags_optimized_by_tagsafe_js).each do |num_tags_optimized_by_tagsafe_js, page_loads|
      json["#{num_tags_optimized_by_tagsafe_js}_optimizations"] = {
        TimeToFirstBytePerformanceMetric.to_s => (page_loads.sum{ |pl| pl.time_to_first_byte_performance_metric.value } / page_loads.count),
        DomCompletePerformanceMetric.to_s => (page_loads.sum{ |pl| pl.dom_complete_performance_metric.value } / page_loads.count),
        DomInteractivePerformanceMetric.to_s => (page_loads.sum{ |pl| pl.dom_interactive_performance_metric.value  } / page_loads.count),
        TotalBlockingTimePerformanceMetric.to_s => (page_loads.sum{ |pl| pl.total_blocking_time_performance_metric&.value || 0 } / page_loads.count),
        FirstContentfulPaintPerformanceMetric.to_s => (page_loads.sum{ |pl| pl.first_contentful_paint_performance_metric.value } / page_loads.count)
      }
    end
    json
  end
end