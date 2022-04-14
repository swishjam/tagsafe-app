class PerformanceMetricsDictionary
  class << self
    def METRIC_DEFINITIONS
      {
        dom_complete: "All of the processing is complete and all of the resources on the page (images, stylesheets, javascript etc.) have finished downloading - in other words, the loading spinner has stopped spinning.",
        dom_interactive: "Marks the point when the browser has finished parsing all of the HTML and DOM construction is complete.",
        dom_content_loaded: "Typically marks when both the DOM and CSSOM are ready. If there is no parser blocking JavaScript then DOMContentLoaded will fire immediately after DOM Interactive.",
        first_contentful_paint: "Occurs when a browser first renders any content from the document object model (DOM), including any text, images, non-white canvas, or scalable vector graphics (SVG) onto the page.",
        script_duration: "The combined duration of all JavaScript execution.", 
        task_duration: "The combined duration of all tasks performed by the browser."  
      }.with_indifferent_access
    end
  end
end