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
      font_awesome_icon('<i class="fab fa-js-square"></i>', color: color)
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

  def loading_submit_button(btn_text = nil, button_class: nil, &block)
    "<button type='submit' class='tagsafe-btn loading-button #{button_class}'>
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
    "/tags/#{tag.id}/audits"
  end

  def modal_link(modal_html_path, klass: nil, text: nil, &block)
    link = if text
            link_to text, modal_html_path, class: klass, data: { controller: 'modal_trigger', turbo_frame: 'server_loadable_modal' }
           else
             inner_html = capture(&block)
             link_to(modal_html_path, class: klass, data: { controller: 'modal_trigger', turbo_frame: 'server_loadable_modal' }) { inner_html }
           end
    link.html_safe
  end

  def render_as_modal(title:, turbo_frame_name: 'server_loadable_modal', &block)
    provided_html = capture(&block)    
    combined_html = <<-HTML
      <div id='server-loadable-modal-container' class='tagsafe-modal-container show' data-controller='server-loadable-modal'>
        <div class='tagsafe-modal-backdrop'>
        </div>
        <div id='server-loadable-modal' class='tagsafe-modal'>
          <div class='tagsafe-modal-header text-start'>
            <span class='tagsafe-circular-btn close' data-action='click->server-loadable-modal#hide'><i class='fa fa-times'></i></span>
            <h4 class='tagsafe-modal-title' data-confirmation-modal-target='title'>#{title}</h4>
          </div>
          <div class='tagsafe-modal-divider'>
          </div>
          <div class="tagsafe-modal-dynamic-content">
            #{provided_html}
          </div>
          <div class="tagsafe-modal-loading-container hidden mb-3">
            <span class='spinner-border tagsafe-spinner medium'></span>
          </div>
        </div>
      </div>
    HTML
    turbo_frame_tag(turbo_frame_name) { combined_html.html_safe }
  end
end