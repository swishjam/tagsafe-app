require "test_helper"
require "generators/stimulus/stimulus_generator"

class StimulusGeneratorTest < Rails::Generators::TestCase
  tests StimulusGenerator
  destination Rails.root.join('tmp/generators')
  setup :prepare_destination

  # test "generator runs without errors" do
  #   assert_nothing_raised do
  #     run_generator ["arguments"]
  #   end
  # end
end
