#update_prepaid_orders.rb
require 'dotenv'
Dotenv.load
require 'httparty'
require 'resque'
require 'active_record'
require "sinatra/activerecord"

#require_relative 'resque_helper'
Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }



module FixPrepaidOrders
    class ChangePrepaid

        def initialize
            Dotenv.load
            @apikey = ENV['ELLIE_API_KEY']
            @shopname = ENV['ELLIE_SHOPNAME']
            @password = ENV['ELLIE_PASSWORD']
            @recharge_access_token = ENV['RECHARGE_ACCESS_TOKEN']
            @my_header = {
                "X-Recharge-Access-Token" => @recharge_access_token
            }
            @my_change_charge_header = {
                "X-Recharge-Access-Token" => @recharge_access_token,
                "Accept" => "application/json",
                "Content-Type" =>"application/json"
            }

          end

          def setup_prepaid_orders
            puts "Starting set up prepaid orders"
            my_end_month = Date.today.end_of_month
            my_end_month_str = my_end_month.strftime("%Y-%m-%d")
            puts "End of the month = #{my_end_month_str}"

            my_start_month_plus = Date.today 
            my_start_month_plus = my_start_month_plus >> 1
            my_start_month_plus = my_start_month_plus.end_of_month + 1
            my_start_month_plus_str = my_start_month_plus.strftime("%Y-%m-%d")
            puts "my start_month_plus_str = #{my_start_month_plus_str}"

            new_end = "2020-08-07"

            update_prepaid_sql = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders where  orders.is_prepaid = '1'  and orders.scheduled_at > \'#{my_end_month_str}\' and orders.scheduled_at < \'#{new_end}\' and orders.status = \'QUEUED\'  "


            UpdatePrepaidOrder.delete_all
            
            ActiveRecord::Base.connection.reset_pk_sequence!('update_prepaid')
            ActiveRecord::Base.connection.execute(update_prepaid_sql)
            puts "Done"


          end

          def setup_prepaid_config
            puts "Setting up prepaid config table: prepaid_subscriptions_config"

            UpdatePrepaidConfig.delete_all
            ActiveRecord::Base.connection.reset_pk_sequence!('update_prepaid_config')

            my_products_sql = "select count(update_prepaid.id), order_line_items_fixed.title, order_line_items_fixed.shopify_product_id, order_line_items_fixed.shopify_variant_id from update_prepaid, order_line_items_fixed where order_line_items_fixed.order_id = update_prepaid.order_id group by order_line_items_fixed.title, order_line_items_fixed.shopify_product_id, order_line_items_fixed.shopify_variant_id order by order_line_items_fixed.title"

            ActiveRecord::Base.connection.execute(my_products_sql).each do |row|
                puts row.inspect
                my_product_collection = "FAIL"
                my_title = row['title']

                case my_title
                when /\s2\sitem/i
                    my_product_collection = "Olive Grove - 2 Items"
                when /\s3\sitem/i
                    my_product_collection = "Olive Grove - 3 Items"
                when /\s5\sitem/i
                    my_product_collection = "Olive Grove - 5 Items"
                when "3 MONTHS"
                    my_product_collection = "Olive Grove - 5 Items"
                end



                UpdatePrepaidConfig.create(title: row['title'], product_id: row['shopify_product_id'], variant_id: row['shopify_variant_id'], product_collection: my_product_collection)
            end
            prepaid_sub_config = UpdatePrepaidConfig.all
            prepaid_sub_config.each do |myc|
                puts myc.inspect
            end
            puts "All done setting up prepaid config table"

          end


          def load_inventory_sizes
            OrderUpdatedInventorySize.delete_all
            ActiveRecord::Base.connection.reset_pk_sequence!('orders_updated_inventory_sizes')
      
            CSV.foreach('orders_updated_inventory_sizes.csv', :encoding => 'ISO-8859-1', :headers => true) do |row|
              puts row.inspect
              OrderUpdatedInventorySize.create(product_type: row['product_type'], product_size: row['product_size'], inventory_avail: row['inventory_avail'], inventory_assigned: row['inventory_assigned'])
      
            end
            puts "Here is the new table with values:"
            my_size_breaks = OrderUpdatedInventorySize.all
            my_size_breaks.each do |mys|
                puts mys.inspect
            end

            puts "All done"
      
          end

          def can_allocate(tops, leggings, bra, two_item)
            tops_avail = false
            leggings_avail = false
            bra_avail = false
            leggings_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "leggings", leggings).first
            tops_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "tops", tops).first

            if leggings_avail_inventory.inventory_avail > 0
                leggings_avail = true
            else
                leggings_avail = false
            end

            if tops_avail_inventory.inventory_avail > 0
                tops_avail = true
            else
                tops_avail = false
            end

            unless two_item
                bra_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "sports-bra", bra).first
                if bra_avail_inventory.inventory_avail > 0
                    bra_avail = true
                else
                    bra_avail = false
                end
            else
                #its a two item, we "have" bra size available
                bra_avail = true
            end

            if tops_avail && leggings_avail && bra_avail
                leggings_avail_inventory.inventory_avail -= 1
                tops_avail_inventory.inventory_avail -= 1
                leggings_avail_inventory.inventory_assigned += 1
                tops_avail_inventory.inventory_assigned += 1
                leggings_avail_inventory.save!
                tops_avail_inventory.save!
                unless two_item
                    bra_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "sports-bra", bra).first
                    bra_avail_inventory.inventory_avail -= 1
                    bra_avail_inventory.inventory_assigned += 1
                    bra_avail_inventory.save! 
                else
                    puts "not adjusting tops inventory as its a two item"
                    
                end

                return true
            else
                return false
            end

          end


          def update_prepaid_orders
            my_orders = UpdatePrepaidOrder.where("is_updated = ?", false)
            my_orders.each do |myord|
                puts myord.inspect
                my_temp_line_item = myord.line_items.first['properties']
                puts my_temp_line_item
                temp_prod_collection_h = my_temp_line_item
                .select { |x| x['name'] == 'product_collection'}
                temp_prod_collection = temp_prod_collection_h.first['value']
                temp_leggings_h = my_temp_line_item
                .select { |x| x['name'] == 'leggings'}
                temp_leggings = temp_leggings_h.first['value']
                temp_tops_h = my_temp_line_item
                .select { |x| x['name'] == 'tops'}
                temp_tops = temp_tops_h.first['value']

                temp_sports_bra_h = my_temp_line_item
                .select { |x| x['name'] == 'sports-bra' }
                if temp_sports_bra_h != []
                    temp_sports_bra = temp_sports_bra_h.first['value']
                else
                    temp_sports_bra = nil
                end
                
                puts "temp_leggings: #{temp_leggings}"
                puts "temp_tops: #{temp_tops}"
                puts "temp_sports_bra: #{temp_sports_bra}"
                puts "temp_prod_collection: #{temp_prod_collection}"

                two_item_collection = false
                if temp_prod_collection =~ /\s2\sitem/i
                    two_item_collection = true
                else
                    two_item_collection = false
                end

                allocate_ok = can_allocate(temp_tops, temp_leggings, temp_sports_bra, two_item_collection)
                puts allocate_ok
                if allocate_ok
                    #myord.is_updated = 't'
                    #myord.save!
                    puts "--------------------"
                    puts myord.line_items.inspect
                    puts "----------------------"
                    shopify_product_id = myord.line_items.first['shopify_product_id']
                    puts "shopify_product_id = #{shopify_product_id}"
                    new_order_info = UpdatePrepaidConfig.find_by_product_id(shopify_product_id)

                    puts "New order info: #{new_order_info.title}, #{new_order_info.product_collection}, #{new_order_info.product_id}, #{new_order_info.variant_id}, "

                else
                    puts "Skipping this one, can't allocate"
                end
            end

            puts "All done with orders"
          end


    end
end