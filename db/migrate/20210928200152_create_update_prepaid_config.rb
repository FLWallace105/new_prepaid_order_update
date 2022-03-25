class CreateUpdatePrepaidConfig < ActiveRecord::Migration[6.0]
  def change
    create_table "update_prepaid_config", force: :cascade do |t|
      t.string "title"
      t.string "product_id"
      t.string "variant_id"
      t.string "product_collection"
    end
  

  end
end
