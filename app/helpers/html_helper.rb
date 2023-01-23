module HtmlHelper
  class << self
    def PASSED_ICON(color: nil)
      font_awesome_icon('far fa-check-circle', color: color)
    end
  
    def FAILED_ICON(color: nil)
      font_awesome_icon('far fa-times-circle', color: color)
    end

    def WARNING_ICON(color: nil)
      font_awesome_icon('fas fa-exclamation-triangle', color: color)
    end

    def QUESTION_MARK_ICON(color: nil)
      font_awesome_icon('far fa-question-circle', color: color)
    end

    def CODE_FILE_ICON(color: nil)
      font_awesome_icon('far fa-file-code', color: color)
    end

    def HTTP_REQUEST_ICON(color: nil)
      font_awesome_icon("fas fa-exchange-alt", color: color)
    end

    def DOCUMENT_FILE_ICON(color: nil)
      font_awesome_icon('far fa-file-alt', color: color)
    end

    def JAVASCRIPT_ICON(color: nil)
      font_awesome_icon('fab fa-js-square', color: color)
    end

    private

    def font_awesome_icon(klass, color: nil)
      if color
        "<i class='#{klass}' style='color: #{color}'></i>".html_safe
      else
        "<i class='#{klass}'></i>".html_safe
      end
    end
  end

  def loading_submit_button(btn_text = nil, button_class: nil, type: 'tagsafe-btn', &block)
    "<button type='submit' class='#{type == 'floating' ? 'floating-btn' : 'tagsafe-btn'} loading-button #{button_class}'>
      <span class='submit-text'>
        #{block_given? ? capture(&block) : btn_text}
      </span>
      #{display_loading_icon color: 'white', size: 'small'}
    </button>".html_safe
  end
  alias submit_loading_button loading_submit_button

  def display_loading_spinner(locals = {})
    render 'partials/utils/spinner', locals
  end
  alias display_loading_icon display_loading_spinner

  def asset_cdn_url(path)
    "#{ENV['ASSET_CDN_DOMAIN']}#{path}"
  end

  def create_audit_path(tag)
    "/tags/#{tag.uid}/audits"
  end

  def modal_link(modal_html_path, klass: nil, text: nil, class: nil, &block)
    link = if text
            link_to text, modal_html_path, class: klass, data: { controller: 'modal_trigger', turbo_frame: 'server_loadable_modal' }
           else
             inner_html = capture(&block)
             link_to(modal_html_path, class: klass, data: { controller: 'modal_trigger', turbo_frame: 'server_loadable_modal' }) { inner_html }
           end
    link.html_safe
  end
  alias modal_link_to modal_link

  def render_as_modal(title:, sub_title: nil, turbo_frame_name: 'server_loadable_modal', hide_close_btn: false, &block)
    provided_html = capture(&block)    
    combined_html = <<~HTML
      <div id='server-loadable-modal-container' data-controller='server-loadable-modal'>
        <div class="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true">
          <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>

          <div class="fixed inset-0 z-10 overflow-y-auto">
            <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
              <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6">
                <h4 class='text-lg font-medium' data-server-loadable-modal-target='title'>#{title}</h4>
                #{if sub_title.present?
                    "<p data-server-loadable-modal-target='subTitle' class='text-sm text-gray-500' data-server-loadable-modal-target='subTitle'>#{sub_title}</p>"
                  end}
                <hr class='mt-2'/>
                <div class="absolute top-3 right-0 hidden pt-4 pr-4 sm:block">
                  <button type="button" 
                          data-action='server-loadable-modal#close'
                          class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
                    <span class="sr-only">Close</span>
                    <!-- Heroicon name: outline/x-mark -->
                    <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                </div>
                <div data-server-loadable-modal-target='dynamicContent'>
                  #{provided_html}
                </div>
                <div data-server-loadable-modal-target='loadingIndicator' class="mt-5 mb-5 text-center hidden">
                  #{display_loading_icon}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    HTML
    turbo_frame_tag(turbo_frame_name) { combined_html.html_safe }
  end
end