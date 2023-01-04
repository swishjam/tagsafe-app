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

  def get_average_metric(metric_klass, page_url)
    all_without_tagsafe = metric_klass.includes(:page_url, :page_load).where(page_load: { num_tags_optimized_by_tagsafe_js: 0..1 }, page_url: { id: page_url.id }).where.not(value: 0).where.not(value: nil)
    all_with_tagsafe = metric_klass.includes(:page_url, :page_load).where(page_load: { num_tags_optimized_by_tagsafe_js: 1.. }, page_url: { id: page_url.id }).where.not(value: 0).where.not(value: nil)
    total_page_loads = metric_klass.includes(:page_url).where(page_url: page_url).where.not(value: 0).where.not(value: nil).count
    {
      total_count_without_tagsafe: all_without_tagsafe.count,
      total_count_with_tagsafe: all_with_tagsafe.count,
      avg_without_tagsafe: all_without_tagsafe.sum(:value) / total_page_loads,
      avg_with_tagsafe: all_with_tagsafe.sum(:value) / total_page_loads
    }
  end
end