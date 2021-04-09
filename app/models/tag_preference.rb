class TagPreference < ApplicationRecord
  belongs_to :tag

  def self.create_default(tag)
    create(
      tag: tag,
      num_test_iterations: 3,
      should_run_audit: true,
      url_to_audit: tag.domain.url
    )
  end
end