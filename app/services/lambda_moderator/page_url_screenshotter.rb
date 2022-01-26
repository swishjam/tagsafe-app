# module LambdaModerator
#   class PageScreenshotter
#     lambda_service 'html-snapshotter'
#     lambda_function 'takeSnapshot'

#     def initialize(page_url)
#       @page_url = page_url
#     end

#     def request_payload
#       {
#         url: @page_url.full_url,
#         third_party_tag_urls_and_rules_to_inject: [],
#         include_html_snapshot: 'false'
#       }
#     end
#   end
# end