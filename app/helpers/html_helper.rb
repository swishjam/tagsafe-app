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

  def loading_submit_button(btn_text, button_class: nil)
    "<button type='submit' class='tagsafe-btn loading-button #{button_class}'><span class='submit-text'>#{btn_text}</span>#{display_loading_icon color: 'white', size: 'small'}</button>".html_safe
  end
  alias submit_loading_button loading_submit_button

  def display_loading_spinner(locals = {})
    render 'partials/utils/spinner', locals
  end
  alias display_loading_icon display_loading_spinner

  def asset_cdn_url(path)
    "#{ENV['ASSET_CDN_DOMAIN']}#{path}"
  end
end