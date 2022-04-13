class CreateDomainAudits < ActiveRecord::Migration[6.1]
  def up
    create_table :domain_audits do |t|
      t.string :uid, index: true
      t.references :domain
      t.references :page_url
      t.string :error_message
      t.datetime :completed_at
      t.timestamps
    end

    add_reference :performance_audits, :domain_audit
    add_reference :delta_performance_audits, :domain_audit

    add_column :domains, :is_generating_third_party_impact_trial, :boolean
    remove_column :domains, :current_performance_audit_calculator_id
  end

  def down
  end
end
