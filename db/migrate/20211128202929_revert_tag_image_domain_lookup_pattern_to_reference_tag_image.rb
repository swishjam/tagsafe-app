class RevertTagImageDomainLookupPatternToReferenceTagImage < ActiveRecord::Migration[6.1]
  def change
    rename_column :tag_image_domain_lookup_patterns, :tag_id, :tag_image_id
  end
end
