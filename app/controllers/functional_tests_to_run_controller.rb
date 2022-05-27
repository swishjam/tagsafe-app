class FunctionalTestsToRunController < LoggedInController
  def create
    tag = current_domain.tags.find_by(uid: params[:functional_test_to_run][:tag_uid])
    functional_test.enable_for_tag(tag)
    render turbo_stream: turbo_stream.replace(
      "functional_test_#{functional_test.uid}_functional_tests_to_run",
      partial: 'functional_tests_to_run/index',
      locals: { functional_test: functional_test }
    )
  end

  def destroy
    tag_to_run_on = functional_test.tags_to_run_on.find_by!(uid: params[:uid])
    tag_to_run_on.destroy!
    render turbo_stream: turbo_stream.replace(
      "functional_test_#{functional_test.uid}_functional_tests_to_run",
      partial: 'functional_tests_to_run/index',
      locals: { functional_test: functional_test }
    )
  end

  private

  def functional_test
    @functional_test ||= current_domain.functional_tests.find_by!(uid: params[:functional_test_uid])
  end
end