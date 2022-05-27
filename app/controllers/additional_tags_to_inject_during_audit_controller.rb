class AdditionalTagsToInjectDuringAuditController < LoggedInController
  def create
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    tag_to_inject = current_domain.tags.find_by(uid: params[:tag_to_inject_uid])
    tag.additional_tags_to_inject_during_audit.create!(tag_to_inject: tag_to_inject)
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_additional_tags_to_inject_during_audit",
      partial: 'additional_tags_to_inject_during_audit/index',
      locals: {
        domain: current_domain,
        tag: tag,
        injectable_tags: current_domain.tags.is_third_party_tag.where.not(id: [tag.id].concat(tag.additional_tags_to_inject_during_audit.collect(&:id)))
      }
    )
  end

  def destroy
    tag = current_domain.tags.find_by(uid: params[:tag_uid])
    additional_tag_to_inject_during_audit = tag.additional_tags_to_inject_during_audit.find_by(uid: params[:uid])
    additional_tag_to_inject_during_audit.destroy
    render turbo_stream: turbo_stream.replace(
      "tag_#{tag.uid}_additional_tags_to_inject_during_audit",
      partial: 'additional_tags_to_inject_during_audit/index',
      locals: {
        domain: current_domain,
        tag: tag,
        injectable_tags: current_domain.tags.is_third_party_tag.where.not(id: [tag.id].concat(tag.additional_tags_to_inject_during_audit.collect(&:id)))
      }
    )
  end
end