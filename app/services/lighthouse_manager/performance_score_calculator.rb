class LighthouseManager::PerformanceScoreCalculator
  WEIGHTS = {
    'first-contentful-paint' => 0.15,
    'speed-index' => 0.15,
    'largest-contentful-paint' => 0.25,
    'interactive' => 0.15,
    'total-blocking-time' => 0.25,
    'cumulative-layout-shift' => 0.05
  }

  def initialize(first_contentful_paint_score:, speed_index_score:, largest_contentful_paint_score:, interactive_score:, total_blocking_time_score:, cumulative_layout_shift_score:)
    @first_contentful_paint_score = first_contentful_paint_score
    @speed_index_score = speed_index_score
    @largest_contentful_paint_score = largest_contentful_paint_score
    @interactive_score = interactive_score
    @total_blocking_time_score = total_blocking_time_score
    @cumulative_layout_shift_score = cumulative_layout_shift_score
  end

  def calculate!
    calculate_weighted_score
  end

  private

  def calculate_weighted_score
    score = 0
    score_matrix.each do |score_arr|
      score += weighted_score(score_arr[0], score_arr[1])
    end
    score
  end

  def score_matrix
    [
      [@first_contentful_paint_score, 'first-contentful-paint'],
      [@speed_index_score, 'speed-index'],
      [@largest_contentful_paint_score, 'largest-contentful-paint'],
      [@interactive_score, 'interactive'],
      [@total_blocking_time_score, 'total-blocking-time'],
      [@cumulative_layout_shift_score, 'cumulative-layout-shift']
    ]
  end

  def weighted_score(score, weight_key)
    score * WEIGHTS[weight_key]
  end
end