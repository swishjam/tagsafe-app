class CreateLintRules < ActiveRecord::Migration[5.2]
  def change
    create_table :lint_rules do |t|
      t.string :rule
      t.string :description
    end

    create_table :organization_lint_rules do |t|
      t.string :organization_id
      t.integer :lint_rule_id
      t.integer :severity
    end
  end
end
