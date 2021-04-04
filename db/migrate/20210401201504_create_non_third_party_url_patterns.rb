class CreateNonThirdPartyUrlPatterns < ActiveRecord::Migration[5.2]
  def change
    create_table :non_third_party_url_patterns do |t|
      t.references :domain
      t.string :pattern
    end
  end
end
