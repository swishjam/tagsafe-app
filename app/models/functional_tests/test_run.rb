class TestRun < ApplicationRecord
  belongs_to :functional_test
  has_one :puppeteer_recording, as: :initiator, dependent: :destroy
  accepts_nested_attributes_for :puppeteer_recording
  has_many :screenshots, class_name: 'TestRunScreenshot', dependent: :destroy
  accepts_nested_attributes_for :screenshots

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :passed, -> { where(passed: true) }
  scope :failed, -> { where(passed: false) }

  def status
    pending? ? 'running' :
      passed? ? 'passed' : 'failed'
  end

  def completed?
    !pending?
  end

  def pending?
    completed_at.nil?
  end

  def passed?
    return false if pending?
    passed
  end

  def failed?
    return false if pending?
    !passed?
  end

  def passed!(results, logs: nil, screenshots: [], puppeteer_recording: nil)
    _completed!(true, results, logs, screenshots, puppeteer_recording)
    after_passed if respond_to?(:after_passed)
  end

  def failed!(results, logs: nil, screenshots: [], puppeteer_recording: nil)
    _completed!(false, results, logs, screenshots, puppeteer_recording)
    after_failed if respond_to?(:after_failed)
  end

  private

  def _completed!(passed, results, logs, screenshots, puppeteer_recording)
    update_args = { passed: passed, results: results, logs: logs, screenshots_attributes: screenshots }
    update_args[:puppeteer_recording_attributes] = puppeteer_recording unless puppeteer_recording.nil? || puppeteer_recording[:s3_url].nil?
    update!(update_args)
  end
end