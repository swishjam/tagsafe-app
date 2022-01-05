module HtmlHelper
  class << self
    def PASSED_ICON(color: nil)
      if color
        "<i class='far fa-check-circle' style='color: #{color}'></i>".html_safe
      else
        "<i class='far fa-check-circle'></i>".html_safe
      end
    end
  
    def FAILED_ICON(color: nil)
      if color
        "<i class='far fa-times-circle' style='color: #{color}'></i>".html_safe
      else
        "<i class='far fa-times-circle'></i>".html_safe
      end
    end

    def WARNING_ICON(color: nil)
      if color
        "<i class='fas fa-exclamation-triangle' style='color: #{color}'></i>".html_safe
      else
        "<i class='fas fa-exclamation-triangle'></i>".html_safe
      end
    end

    def QUESTION_MARK_ICON(color: nil)
      if color
        "<i class='far fa-question-circle' style='color: #{color}'></i>".html_safe
      else
        "<i class='far fa-question-circle'></i>".html_safe
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
end