module HtmlHelper
  class << self
    def PASSED_ICON(colorized = true)
      "<i class='far fa-check-circle green-text'></i>".html_safe
    end
  
    def FAILED_ICON(colorized = true)
      "<i class='far fa-times-circle red-text'></i>".html_safe
    end
  end

  def loading_submit_button(btn_text, button_class: nil)
    "<button type='submit' class='tagsafe-btn loading-button #{button_class}'><span class='submit-text'>#{btn_text}</span>#{display_loading_icon color: 'white', size: 'small'}</button>".html_safe
  end
  alias submit_loading_button loading_submit_button

  def display_loading_spinner(opts = {})
    render 'partials/utils/spinner', opts
  end
  alias display_loading_icon display_loading_spinner
end