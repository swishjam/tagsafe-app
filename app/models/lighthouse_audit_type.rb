# class LighthouseAuditType < ApplicationRecord
#   has_many :lighthouse_audit_results

#   def self.CURRENT_TAG
#     @current_tag ||= find_by!(name: 'Current Tag')
#   end

#   def self.WITHOUT_TAG
#     @without_tag ||= find_by!(name: 'Without Tag')
#   end

#   def self.AVERAGE_CURRENT_TAG
#     @average_current_tag ||= find_by!(name: 'Average Current Tag')
#   end

#   def self.AVERAGE_WITHOUT_TAG
#     @average_without_tag ||= find_by!(name: 'Average Without Tag')
#   end

#   def self.DELTA
#     @average_delta ||= find_by!(name: 'Delta')
#   end
# end