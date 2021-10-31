namespace :seed do
  task :mandatory_data => :environment do
    puts "Beginning seed."
    puts "Creating roles."
    %w[user user_admin tagsafe_admin].each do |role|
      unless Role.find_by(name: role)
        Role.create(name: role)
      end
    end

    puts "Creating Execution Reasons."
    execution_reasons =  ['Manual Execution', 'Scheduled Execution', 'New Tag Version', 'Activated Tag', 'Test', 'Initial Audit', 'Retry']
    execution_reasons.each do |name|
      unless ExecutionReason.find_by(name: name)
        ExecutionReason.create(name: name)
      end
    end
  end
end