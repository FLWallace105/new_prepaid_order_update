class CreateConfigUpdatePrepaidSubs < ActiveRecord::Migration[6.0]
  def up
    create_table :prepaid_subscriptions_config do |t|
      t.string :product_title
      t.string :shopify_product_id
      t.string :product_collection
      
  
    end
    
  end
  
  def down
    drop_table :prepaid_subscriptions_config
  end
end
