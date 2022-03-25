class CreatePrepaidSubscriptionsUpdatedConfig < ActiveRecord::Migration[6.0]
  def change
    create_table "prepaid_subscriptions_config", force: :cascade do |t|
      t.string "product_title"
      t.string "shopify_product_id"
      t.string "product_collection"
    end
  end
end
