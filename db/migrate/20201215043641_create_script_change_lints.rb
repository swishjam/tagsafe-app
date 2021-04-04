class CreateTagVersionLints < ActiveRecord::Migration[5.2]
  def change
    create_table :lint_results do |t|
      t.integer :tag_version_id
      t.string :rule_id
      t.string :message
      t.string :source
      t.integer :line
      t.integer :column
      t.string :node_type
      t.boolean :fatal
    end

    create_table :tag_lint_results do |t|
      t.integer :tag_id
      t.integer :lint_result_id
    end
  end
end
