class UrlCrawl < ApplicationRecord
  include HasExecutedLambdaFunction
  acts_as_paranoid
  
  belongs_to :domain
  belongs_to :page_url
  has_many :found_tags, class_name: 'Tag', foreign_key: :found_on_url_crawl_id
  alias tags_found found_tags

  scope :pending, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :failed, -> { where.not(error_message: nil) }
  scope :successful, -> { completed.where(error_message: nil ) }

  after_create_commit { broadcast_replace_to "#{domain_id}_current_crawl", target: "#{domain_id}_current_crawl", partial: 'urls_to_crawl/current_crawl', locals: { domain: domain } }
  after_update_commit do
    broadcast_replace_to "#{domain_id}_current_crawl", target: "#{domain_id}_current_crawl", partial: 'urls_to_crawl/current_crawl', locals: { domain: domain }
    broadcast_replace_to "#{uid}_url_crawl", target: "#{uid}_url_crawl", partial: 'url_crawls/status', locals: { url_crawl: self }
  end

  def self.most_recent
    most_recent_first(timestamp_column: :enqueued_at).limit(1).first
  end

  def found_tag!(
    tag_url,
    load_type: nil,
    enabled: Util.env_is_true('NEW_TAGS_ARE_ENABLED_BY_DEFAULT'), 
    is_allowed_third_party_tag: false, 
    is_third_party_tag: true,
    initial_crawl: false,
    should_log_tag_checks: true,
    consider_query_param_changes_new_tag: false,
    performance_audit_iterations: Flag.flag_value_for_objects(domain, domain.organization, slug: 'num_performance_audit_iterations').to_i
  )
    parsed_url = URI.parse(tag_url)
    tag = found_tags.new(
      domain: domain,
      full_url: tag_url,
      url_domain: parsed_url.host,
      url_path: parsed_url.path,
      url_query_param: parsed_url.query,
      load_type: load_type,
      found_on_page_url: page_url,
      tag_preferences_attributes: {
        enabled: enabled,
        is_allowed_third_party_tag: is_allowed_third_party_tag,
        is_third_party_tag: is_third_party_tag,
        should_log_tag_checks: should_log_tag_checks,
        consider_query_param_changes_new_tag: consider_query_param_changes_new_tag,
        performance_audit_iterations: performance_audit_iterations
      }
    )
    if tag.save
      url_to_audit = tag.urls_to_audit.create(page_url: page_url)
      # url_to_audit.generate_tagsafe_hosted_site_now! if Flag.flag_is_true(domain.organization, 'tagsafe_hosted_site_enabled')
      AfterTagCreationJob.perform_later(tag, initial_crawl)
      tag
    else
      Rails.logger.error "Tried adding #{tag_url} to domain #{domain.url} but failed to save. Error: #{tag.errors.full_messages.join('\n')}"
      Resque.logger.error "Tried adding #{tag_url} to domain #{domain.url} but failed to save. Error: #{tag.errors.full_messages.join('\n')}"
    end
  end

  # def unremove_tag_from_site!(tag)
  #   TagRemovedFromSiteEvent.create!(triggerer: tag)
  # end

  # def query_params_changed_for_tag!(tag, new_full_url)
  #   parsed_new_url = URI.parse(new_full_url)
  #   TagUrlQueryParamsChangedEvent.create!(triggerer: tag, metadata: {
  #     removed_url_query_params: url_query_param, 
  #     added_url_query_params: parsed_new_url.query 
  #   })
  # end

  # def tag_removed_from_site!(tag)
  #   removed_from_site_tag_events.create!(tag: tag)
  # end

  def pending?
    completed_at.nil?
  end

  def completed?
    !pending?
  end

  def failed?
    !error_message.nil?
  end

  def successful?
    !failed? && completed?
  end

  def completed!
    touch(:completed_at)
    update_column(:seconds_to_complete, completed_at - enqueued_at)
  end

  def errored!(error_msg)
    update(error_message: error_msg)
    completed!
  end
end