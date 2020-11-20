class GeppettoModerator::Receiver
  def initialize(class_string, data)
    @klass = "GeppettoModerator::Receivers::#{class_string}".constantize
    @data = data
  end

  def receive!
    @klass.new(@data).receive!
  end
end