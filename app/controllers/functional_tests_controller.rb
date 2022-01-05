class FunctionalTestsController < LoggedInController
  def index
    @functional_tests = current_domain.functional_tests.order(disabled_at: :ASC, passed_dry_run: :DESC, run_on_all_tags: :DESC)
    render_breadcrumbs(
      { url: tags_path, text: 'Monitor Center' },
      { text: 'Test Suite', active: true }
    )
  end

  def new
    @functional_test = current_domain.functional_tests.new
    render_breadcrumbs(
      { url: tags_path, text: 'Monitor Center' },
      { url: functional_tests_path, text: 'Test Suite' },
      { text: 'New Functional Test', active: true }
    )
  end

  def show
    @functional_test = current_domain.functional_tests.find(params[:id])
    render_breadcrumbs(
      { url: tags_path, text: 'Monitor Center' },
      { url: functional_tests_path, text: 'Test Suite' },
      { text: @functional_test.title, active: true }
    )
  end

  def tags_to_run_on
    @functional_test = current_domain.functional_tests.find(params[:id])
    render_breadcrumbs(
      { url: tags_path, text: 'Monitor Center' },
      { url: functional_tests_path, text: 'Test Suite' },
      { text: @functional_test.title, active: true }
    )
  end

  def create
    params[:functional_test][:created_by_user_id] = current_user.id
    params[:functional_test][:expected_results] = params[:functional_test][:expected_results].blank? ? nil : params[:functional_test][:expected_results]
    @functional_test = current_domain.functional_tests.new(functional_test_params)
    if @functional_test.save
      dry_test_run = @functional_test.perform_dry_run_later!
      redirect_to functional_test_test_run_path(@functional_test, dry_test_run)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @functional_test = current_domain.functional_tests.find(params[:id])
  end

  def update
    functional_test = current_domain.functional_tests.find(params[:id])
    if functional_test.update(functional_test_params)
      should_run_dry_test_run = functional_test.saved_changes['puppeteer_script'] || functional_test.saved_changes['expected_results'] || params[:force_validation]
      if should_run_dry_test_run
        functional_test.update_column :passed_dry_run, false
        dry_test_run = functional_test.perform_dry_run_later!
        redirect_to functional_test_test_run_path(functional_test, dry_test_run)
      else
        current_user.broadcast_notification("Test updated.", notification_type: 'success')
        render turbo_stream: turbo_stream.replace(
          params[:turbo_frame] || "functional_test_form",
          partial: params[:turbo_partial] || 'functional_tests/form',
          locals: { functional_test: functional_test }
        )
      end
    else
      render turbo_stream: turbo_stream.replace(
        "functional_test_form",
        partial: 'functional_tests/form',
        locals: { functional_test: functional_test, errors: functional_test.errors.full_messages }
      )
    end
  end

  def toggle_disable
    functional_test = current_domain.functional_tests.find(params[:id])
    if functional_test.enabled?
      functional_test.disable!
      current_user.broadcast_notification("Test '#{functional_test.title}' disabled.")
    else
      functional_test.enable!
      current_user.broadcast_notification("Test '#{functional_test.title}' enabled.")
    end
    render turbo_stream: turbo_stream.replace(
      "functional_test_#{functional_test.uid}",
      partial: 'functional_tests/show',
      locals: { functional_test: functional_test }
    )
  end

  private

  def functional_test_params
    params.require(:functional_test).permit(:title, :description, :puppeteer_script, :expected_results, :created_by_user_id, :run_on_all_tags)
  end
end