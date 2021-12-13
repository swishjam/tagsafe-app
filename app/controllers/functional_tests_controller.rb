class FunctionalTestsController < LoggedInController
  def index
    @functional_tests = current_domain.functional_tests
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

  def create
    params[:functional_test][:created_by_user_id] = current_user.id
    params[:functional_test][:expected_results] = params[:functional_test][:expected_results].blank? ? nil : params[:functional_test][:expected_results]
    @functional_test = current_domain.functional_tests.new(new_functional_test_params)
    if @functional_test.save
      dry_test_run = @functional_test.run_dry_run!
      render turbo_stream: turbo_stream.replace(
        "new_functional_test",
        partial: 'functional_tests/pending_dry_run',
        locals: { functional_test: @functional_test, dry_test_run: dry_test_run }
      )
    else
      render :new, :unprocessable_entity
    end
  end

  def update
    @functional_test = current_domain.functional_tests.find(params[:id])
    if @functional_test.update(update_functional_test_params)
      render turbo_stream: turbo_stream.replace(
        "tags_to_run_functional_tests_for_functional_test_#{@functional_test.uid}",
        partial: 'functional_tests_to_run/form_for_functional_test',
        locals: { functional_test: @functional_test }
      )
    else
      render turbo_stream: turbo_stream.replace(
        "tags_to_run_functional_tests_for_functional_test_#{@functional_test.uid}",
        partial: 'functional_tests_to_run/form_for_functional_test',
        locals: { functional_test: @functional_test, errors: @functional_test.errors.full_messages }
      )
    end
  end

  def validate
    functional_test = current_domain.functional_tests.find(params[:id])
    dry_test_run = functional_test.run_dry_run!
    render turbo_stream: turbo_stream.replace(
      "functional_test_#{functional_test.uid}_un_validated",
      partial: 'functional_tests/un_validated',
      locals: { functional_test: functional_test, dry_test_run: dry_test_run }
    )
  end

  private

  def update_functional_test_params
    params.require(:functional_test).permit(:title, :description, :run_on_all_tags)
  end

  def new_functional_test_params
    params.require(:functional_test).permit(:title, :description, :puppeteer_script, :expected_results, :created_by_user_id)
  end
end