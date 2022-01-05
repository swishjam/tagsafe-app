class AddMsAvailableToStopWithinToPuppeteerRecording < ActiveRecord::Migration[6.1]
  def up
    add_column :puppeteer_recordings, :ms_available_to_stop_within, :integer
    add_column :test_runs, :script_execution_ms, :integer
  end

  def down
    remove_column :puppeteer_recordings, :ms_available_to_stop_within
    remove_column :test_runs, :script_execution_ms
  end
end
