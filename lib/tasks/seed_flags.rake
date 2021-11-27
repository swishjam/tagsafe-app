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
        name: 'TagSafe-Hosted Site Option Available',
        slug: 'tagsafe_hosted_site_enabled',
        description: 'Provides the option to have TagSafe host a duplicated front-end version of their site for audits.',
        default_value: 'false'
      },
      {
        name: 'Number of Performance Audits to run per Audit',
        slug: 'num_performance_audit_iterations',
        description: 'Whatever the value of this flag is dictates how many performance audits are run per audit.',
        default_value: '3'
      },
      {
        name: 'Stripe all CSS in Performance Audits',
        slug: 'strip_all_css_in_performance_audits',
        description: 'Removes all CSS from the audited page when running performance audits.',
        default_value: 'false'
      },
      {
        name: 'Stripe all images in Performance Audits',
        slug: 'strip_all_images_in_performance_audits',
        description: 'Removes all img tags from the audited page when running performance audits.',
        default_value: 'false'
      }
    ]

    flags.each do |flag_config|
      existing = Flag.find_by(slug: flag_config[:slug])
      if existing
        puts "#{existing.slug} already exists, skipping..."
      else
        flag = Flag.create!(flag_config)
        puts "Created #{flag.slug} flag."
      end
    end
  end
end