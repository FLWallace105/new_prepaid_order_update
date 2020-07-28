class CreateOrderInventorySizes < ActiveRecord::Migration[6.0]
  def change
    create_table :orders_updated_inventory_sizes do |t|
      t.string :product_type
      t.string :product_size
      t.integer :inventory_avail
      t.integer :inventory_assigned
      

    end

  end
end
