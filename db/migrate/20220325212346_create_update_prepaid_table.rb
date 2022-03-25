class CreateUpdatePrepaidTable < ActiveRecord::Migration[6.0]
  def change

    create_table "update_prepaid" do |t|

      t.string :order_id 
      t.string :transaction_id
      t.string :charge_status
      t.string :payment_processor
      t.integer :address_is_active
      t.string :status
      t.string :order_type
      t.string :charge_id
      t.string :address_id
      t.string :shopify_id
      t.string :shopify_order_id
      t.string :shopify_cart_token
      t.datetime :shipping_date
      t.datetime :scheduled_at
      t.datetime :shipped_date
      t.datetime :processed_at
      t.string :customer_id
      t.string :first_name
      t.string :last_name
      t.integer :is_prepaid
      t.datetime :created_at
      t.datetime :updated_at
      t.string :email
      t.jsonb :line_items
      t.decimal :total_price, precision: 10, scale: 2
      t.jsonb :shipping_address
      t.jsonb :billing_address
      t.datetime :synced_at
      t.boolean :is_updated, default: false




    end




  end
end
