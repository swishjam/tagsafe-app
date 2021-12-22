class FunctionalTest < ApplicationRecord
  belongs_to :domain
  belongs_to :created_by_user, class_name: 'User'
  
  has_many :functional_tests_to_run, class_name: 'FunctionalTestToRun'
  has_many :tags_to_run_tests_on, through: :functional_tests_to_run, source: 'tag', dependent: :destroy
  accepts_nested_attributes_for :functional_tests_to_run

  has_many :test_runs, dependent: :destroy
  has_many :dry_test_runs, class_name: 'DryTestRun'
  has_many :test_runs_with_tag, class_name: 'TestRunWithTag'
  has_many :test_runs_without_tag, class_name: 'TestRunWithoutTag'

  scope :passed_dry_run, -> { where(passed_dry_run: true) }
  scope :has_not_passed_dry_run, -> { where(passed_dry_run: false) }
  
  scope :run_on_all_tags, -> { where(run_on_all_tags: true) }
  scope :do_not_run_on_all_tags, -> { where(run_on_all_tags: false) }

  scope :disabled, -> { where.not(disabled_at: nil) }
  scope :enabled, -> { where(disabled_at: nil) }

  attribute :passed_dry_run, default: false
  attribute :run_on_all_tags, default: false

  after_update :check_if_run_on_all_tags_changed
  
  validate :has_return_in_script_if_expected_results_is_present

  def run_dry_run!
    test_run = dry_test_runs.create!
    RunDryTestRunJob.perform_later(self, test_run)
    test_run
  end

  def disable!
    update!(disabled_at: Time.now)
  end

  def enable!
    update!(disabled_at: nil)
  end

  def disabled?
    !disabled_at.nil?
  end

  def enabled?
    !disabled?
  end

  def has_pending_dry_run?
    dry_test_runs.pending.any?
  end

  def most_recent_dry_test_run
    dry_test_runs.most_recent_first(timestamp_column: :enqueued_at).limit(1).first
  end

  def is_enabled_for_tag?(tag)
    run_on_all_tags || tags_to_run_tests_on.include?(tag)
  end

  def enable_for_tag(tag)
    tags_to_run_tests_on.create(tag: tag)
  end

  private

  def has_return_in_script_if_expected_results_is_present
    if !expected_results.nil? && !puppeteer_script.include?('return ')
      errors.add(:base, "Functional test has an expected return value of `#{expected_results}` but the provided script does not contain an explicit `return` value.")
    end
  end

  def check_if_run_on_all_tags_changed
    if saved_changes['run_on_all_tags']
      run_on_all_tags_became = saved_changes['run_on_all_tags'][1]
      if run_on_all_tags_became == true
        domain.tags.each{ |tag| enable_for_tag(tag) }
      else
        # do nothing, leave each individual functional_tests_to_run to be disabled manually
      end
    end
  end

  # def check_to_run_dry_run
  #   if saved_changes['puppeteer_script']
  #     update_column :passed_dry_run, false
  #     run_dry_run!
  #   end
  # end
end