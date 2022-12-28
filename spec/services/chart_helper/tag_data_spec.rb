require 'rails_helper'

RSpec.describe ChartHelper::TagData do
  before(:each) do
    stub_audit_component_performance
    prepare_test!
    @user = create(:user)
    @container.add_user(@user)
    @tag = create_tag_with_associations
    
    @frozen_time = Time.current
    allow(Time).to receive(:current).and_return(@frozen_time)

    create_audit_for_timestamp(80, @frozen_time - 7.days) # not included
    create_audit_for_timestamp(70, @frozen_time - (1.day + 1.minute)) # not included
    create_audit_for_timestamp(60, @frozen_time - (1.day - 5.minutes)) # included
    create_audit_for_timestamp(50, @frozen_time - 12.hours) # included
    create_audit_for_timestamp(40, @frozen_time - 30.minutes) # included

    @chart_helper = ChartHelper::TagData.new(tag: @tag, time_range: :"24_hours")
  end

  def create_audit_for_timestamp(tagsafe_score, timestamp)
    audit = create(:audit, 
      created_at: timestamp,
      container: @container,
      tag_version: @tag.tag_versions.first, 
      tag: @tag,
      page_url: @tag.page_url_first_found_on, 
      execution_reason: ExecutionReason.MANUAL, 
      initiated_by_container_user: @user.container_user_for(@container),
    )
    # override the calculate tagsafe_score in the Audit's after_complete callback
    audit.update_column :tagsafe_score, tagsafe_score
  end

  describe '#chart_data' do
    it 'only includes data from tag versions created within the timeframe specified' do
      data_points_outside_of_specified_time_range = @chart_helper.chart_data[:data].find_all{ |timestamp, _tagsafe_score| timestamp < @chart_helper.start_datetime  }
      expect(data_points_outside_of_specified_time_range.any?).to be(false)
      expect(@chart_helper.chart_data[:data].count).to be(8)
    end

    it 'adds the correct data points between audits' do
      expect(@chart_helper.chart_data[:data][7]).to eq([@chart_helper.start_datetime, 70.0])
      expect(@chart_helper.chart_data[:data][6]).to eq(
        [@chart_helper.chart_data[:data][5][0] - 1.minute, 70.0]
      )

      expect(@chart_helper.chart_data[:data][5]).to eq([@frozen_time - (1.day - 5.minutes), 60.0])
      expect(@chart_helper.chart_data[:data][4]).to eq(
        [@chart_helper.chart_data[:data][3][0] - 1.minute, 60.0]
      )

      expect(@chart_helper.chart_data[:data][3]).to eq([@frozen_time - 12.hours, 50.0])
      expect(@chart_helper.chart_data[:data][2]).to eq(
        [@chart_helper.chart_data[:data][1][0] - 1.minute, 50.0]
      )

      expect(@chart_helper.chart_data[:data][1]).to eq([@frozen_time - 30.minutes, 40.0])
      expect(@chart_helper.chart_data[:data][0]).to eq([Time.current, 40.0])
    end
  end
end