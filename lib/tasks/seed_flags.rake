namespace :seed do
  task :flags => :environment do
    flags = [
      {
        name: 'Include Page Load Resources in Performance Audits',
        slug: 'include_page_load_resources',
        description: 'Specifies whether performance audits will include a waterfall chart of page resources and load times.',
        default_value: 'false'
      },
      {
        name: 'Maximum Individual Performance Audit Retries',
        slug: 'max_individual_performance_audit_retries',
        description: 'The number of times an indivdual performance audit can fail before failing the entire audit.',
        default_value: '3'
      },
      {
        name: 'Include Performance Traces',
        slug: 'include_performance_trace',
        description: 'Whether or not to include Chrome performance traces in performance audits.',
        default_value: 'false'
      },
      {
        name: 'Inline Injected Script Tags',
        slug: 'inline_injected_script_tags',
        description: 'When running performance audits, turn this to true to inline audited tags rather than a script tag with a src.',
        default_value: 'false'
      },
      {
        name: 'Tagsafe-Hosted Site Option Available',
        slug: 'tagsafe_hosted_site_enabled',
        description: 'Provides the option to have Tagsafe host a duplicated front-end version of their site for audits.',
        default_value: 'false'
      },
      {
        name: 'Number of Performance Audits to run per Audit',
        slug: 'num_performance_audit_iterations',
        description: 'Whatever the value of this flag is dictates how many performance audits are run per audit.',
        default_value: '3'
      },
      {
        name: 'Strip all CSS in Performance Audits',
        slug: 'strip_all_css_in_performance_audits',
        description: 'Removes all CSS from the audited page when running performance audits.',
        default_value: 'false'
      },
      {
        name: 'Strip all images in Performance Audits',
        slug: 'strip_all_images_in_performance_audits',
        description: 'Removes all img tags from the audited page when running performance audits.',
        default_value: 'false'
      }, 
      {
        name: 'Throw an error if DOM Complete is zero in Performance Audits',
        slug: 'performance_audit_throw_error_if_dom_complete_is_zero',
        description: 'When running a performance audit, throw an error if the DOM Complete timestamp does not exceed zero.',
        default_value: 'true'
      },
      {
        name: 'Determine new tag versions by bytesize instead of hashed content',
        slug: 'should_detect_new_releases_based_on_bytesize_changes',
        description: 'Instead of using the tag versions hashed content to determine if a new version was released, if the file changes in size',
        default_value: 'true'
      },
      {
        name: 'Max functional test script execution',
        slug: 'max_functional_test_script_execution_ms',
        description: 'The maximum amount of time (in milliseconds) a functional test\'s script has to complete execution',
        default_value: '20000'
      },
      {
        name: 'Should remove tags when no longer present in URL crawl results',
        slug: 'remove_tags_no_longer_present_in_url_crawls',
        description: 'When value is true, if a URL crawl no longer has a tag that it previously had, mark the tag as `remove-from-site`',
        default_value: 'false'
      },
      {
        name: 'Include page tracing in performance audits',
        slug: 'include_page_tracing',
        description: 'When value is true, performance audits will include a page trace JSON stored in s3',
        default_value: 'true'
      },
      {
        name: 'Override initial HTML request with manipulated page in performance audits',
        slug: 'override_initial_html_request_with_manipulated_page',
        description: 'When value is true, we will intercept initial HTML request in performance audits and replace it with a manipulated version of the page.',
        default_value: 'true'
      },
      {
        name: 'Maximum total successful performance audits allowed before completing an audit',
        slug: 'maximum_total_successful_performance_audit_sets',
        description: "Will hault a Performance Audit when it reaches this number whether we are confident in the Tagsafe Score or not.",
        default_value: '15'
      }, 
      {
        name: 'Minimum number of performance audits required for performance audit to complete',
        slug: 'minimum_performance_audit_sets_to_meet_completion_criteria',
        description: 'A performance audit must complete at least this many sets before being even being considered completed.',
        default_value: '3'
      },
      {
        name: 'Required performance audit Tagsafe Score confidence range',
        slug: 'performance_audit_tagsafe_score_confidence_range_completion_criteria',
        description: 'A performance audit will not be completed until we are 95% sure the Tagsafe Score is +/- this number.',
        default_value: '5'
      }, 
      {
        name: 'Display Tagsafe Score confidence range indicator',
        slug: 'display_tagsafe_score_confidence_range_indicator',
        description: 'Whether a user should see an indicator on Tagsafe Scores for when it is within or outside specified confidence range.',
        default_value: 'false'
      }
    ]

    flags.each do |flag_config|
      existing = Flag.find_by(slug: flag_config[:slug])
      if existing
        puts "#{existing.slug} already exists, updating..."
        existing.update!(flag_config)
      else
        flag = Flag.create!(flag_config)
        puts "Created #{flag.slug} flag."
      end
    end
  end
end