class CreatePrepaidSubscriptionsUpdated < ActiveRecord::Migration[6.0]
  def up
    create_table :prepaid_subscriptions_updated do |t|
      t.string :subscription_id
      t.string :customer_id
      t.datetime :updated_at
      t.datetime :next_charge_scheduled_at
      t.string :product_title
      t.string :status
      t.string :sku
      t.string :shopify_product_id
      t.string :shopify_variant_id
      t.boolean :updated, default: false
      t.datetime :processed_at
      t.jsonb :raw_line_items
      t.datetime :created_at
      t.string :product_collection  
  
    end
    
  end
  
  def down
    drop_table :prepaid_subscriptions_updated
  end

end
