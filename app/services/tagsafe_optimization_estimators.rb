class TagsafeOptimizationsEstimator
  class << self
    def estimate_optimizations_for(page_url, page_load_limit: 250)
      json = {}
      page_url.page_loads
                .includes(:page_load_performance_metrics)
                .most_recent_first.limit(page_load_limit)
                .group_by(&:num_tagsafe_hosted_tags)
                .each do |num_tags_optimized_by_tagsafe_js, page_loads|
        json["#{num_tags_optimized_by_tagsafe_js}_tagsafe_hosted_tags"] = {
          "num_page_loads" => page_loads.count,
          ThirdPartyJsNetworkTimePerformanceMetric.to_s => get_average_metric_for_page_loads(page_loads, :third_party_js_network_time_performance_metric),
          TimeToFirstBytePerformanceMetric.to_s => get_average_metric_for_page_loads(page_loads, :time_to_first_byte_performance_metric),
          DomCompletePerformanceMetric.to_s => get_average_metric_for_page_loads(page_loads, :dom_complete_performance_metric),
          DomInteractivePerformanceMetric.to_s => get_average_metric_for_page_loads(page_loads, :dom_interactive_performance_metric),
          TotalBlockingTimePerformanceMetric.to_s => get_average_metric_for_page_loads(page_loads, :total_blocking_time_performance_metric),
          FirstContentfulPaintPerformanceMetric.to_s => get_average_metric_for_page_loads(page_loads, :first_contentful_paint_performance_metric),
        }
      end
      json
    end
  
    def get_average_metric_for_page_loads(page_loads, metric)
      page_loads_with_metric = page_loads.filter{ |pl| pl.send(:"#{metric}").present? }
      return nil if page_loads_with_metric.none?
      page_loads_with_metric.sum{ |pl| pl.send(:"#{metric}").value } / page_loads_with_metric.count
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
end