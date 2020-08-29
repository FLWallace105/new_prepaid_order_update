#update_prepaid_orders.rb
require 'dotenv'
Dotenv.load
require 'httparty'
require 'resque'
require 'active_record'
require "sinatra/activerecord"

#require_relative 'resque_helper'
Dir[File.join(__dir__, 'models', '*.rb')].each { |file| require file }
Dir[File.join(__dir__, 'lib', '*.rb')].each { |file| require file }


module FixPrepaidOrders
    class ChangePrepaid

        def initialize
            Dotenv.load
            
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

            #update_prepaid_sql = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders where  orders.is_prepaid = '1'  and orders.scheduled_at > \'#{my_end_month_str}\' and orders.scheduled_at < \'#{new_end}\' and orders.status = \'QUEUED\'  "

            update_prepaid_sql = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders, order_collection_sizes where order_collection_sizes.order_id = orders.order_id and  orders.is_prepaid = '1'  and orders.scheduled_at > \'#{my_end_month_str}\' and orders.scheduled_at < \'#{my_start_month_plus_str}\' and orders.status = \'QUEUED\' and (order_collection_sizes.product_collection not ilike 'test%value%'  ) "

            


            UpdatePrepaidOrder.delete_all
            
            ActiveRecord::Base.connection.reset_pk_sequence!('update_prepaid')
            ActiveRecord::Base.connection.execute(update_prepaid_sql)
            puts "Done"


          end

          def fix_single_order(temp_order)
            puts "Fixing Single Order"
            puts "====================="
            puts temp_order.inspect
            puts "+++++++++++++++++++++"
            #need to fix in line_items: title, product_title, product_id, variant_id
            temp_product_title = temp_order.line_items.first['product_title']
            puts "temp_product_title = #{temp_product_title}"

            product_information = {}

            case temp_product_title
            when /\s2\sitem/i
                product_information = {"title" => "3 Months - 2 Items", "product_id" => 2506238492730, "variant_id" => 23656253784122}
            when /\s3\sitem/i
                product_information = {"title" => "3 Months - 3 Items", "product_id" => 2209786298426, "variant_id" => 22212749393978}
            when /\s5\sitem/i
                product_information = {"title" => "3 Months - 5 Items", "product_id" => 2209789771834, "variant_id" => 22212763320378}
            
            else
                product_information = {}  
            end

            temp_order.line_items[0].tap {|myh| myh.delete('shopify_variant_id')}
            temp_order.line_items[0].tap {|myh| myh.delete('shopify_product_id')}
            temp_order.line_items[0].tap {|myh| myh.delete('images')}
            temp_order.line_items[0].tap {|myh| myh.delete('tax_lines')}
            temp_order.line_items[0]['product_id'] = product_information['product_id']
            temp_order.line_items[0]['variant_id'] = product_information['variant_id']
            temp_order.line_items[0]['quantity'] = 1
            temp_order.line_items[0]['title'] = product_information['title']
            temp_order.line_items[0]['product_title'] = product_information['title']

            puts "+++++++++++++++++++++++++++++"
            puts "Sending to ReCharge:"
            puts temp_order.line_items.inspect
            puts "++++++++++++++++++++++++++++"

            #Send to Recharge
            my_data = { "line_items" => temp_order.line_items }
            my_update_order = HTTParty.put("https://api.rechargeapps.com/orders/#{temp_order.order_id}", :headers => @my_change_charge_header, :body => my_data.to_json, :timeout => 80)
            puts my_update_order.inspect
            recharge_header = my_update_order.response["x-recharge-limit"]
            determine_limits(recharge_header, 0.65)
            puts "sleeping 2 secs"
            sleep 2



          end


          def cleanup_scoutside_orders
            puts "Starting clean up of scoutside orders"
            num_orders_fix = 0
            myorders = UpdatePrepaidOrder.all
            myorders.each do |myord|
                puts "--------"
                puts myord.order_id
                #puts myord.line_items.inspect
                temp_title = myord.line_items.first['title']
                temp_product_title = myord.line_items.first['product_title']

                if temp_product_title !~ /month/i
                    puts "#{temp_title}, #{temp_product_title}"
                    num_orders_fix += 1
                    fix_single_order(myord)

                end
                puts "--------"

            end
            puts "We have #{num_orders_fix} orders to fix"

          end

          def setup_prepaid_config
            puts "Setting up prepaid config table: prepaid_subscriptions_config"

            UpdatePrepaidConfig.delete_all
            ActiveRecord::Base.connection.reset_pk_sequence!('update_prepaid_config')

            my_products_sql = "select count(update_prepaid.id), order_line_items_fixed.product_title, order_line_items_fixed.shopify_product_id, order_line_items_fixed.shopify_variant_id from update_prepaid, order_line_items_fixed where order_line_items_fixed.order_id = update_prepaid.order_id group by order_line_items_fixed.product_title, order_line_items_fixed.shopify_product_id, order_line_items_fixed.shopify_variant_id order by order_line_items_fixed.product_title"

            ActiveRecord::Base.connection.execute(my_products_sql).each do |row|
                puts row.inspect
                my_product_collection = "FAIL"
                my_title = row['product_title']

                case my_title
                when /\s2\sitem/i
                    my_product_collection = "Solar Flare - 2 Items"
                when /\s3\sitem/i
                    my_product_collection = "Solar Flare - 3 Items"
                when /\s5\sitem/i
                    my_product_collection = "Solar Flare - 5 Items"
                when "3 MONTHS"
                    my_product_collection = "Solar Flare - 5 Items"
                end



                UpdatePrepaidConfig.create(title: row['product_title'], product_id: row['shopify_product_id'], variant_id: row['shopify_variant_id'], product_collection: my_product_collection)
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
                    puts "not adjusting bra inventory as its a two item"
                    
                end

                return true
            else
                return false
            end

          end

          def update_product_collection(order_array, product_collection)
           # puts "---------------"
           # puts order_array.inspect
           # puts "----------------"
            my_props = order_array.first['properties']
            my_props.map do |myp|
                if myp['name'] == 'product_collection'
                    myp['value'] = product_collection
                end
            end
            return order_array


          end


          def update_prepaid_orders
            my_orders = UpdatePrepaidOrder.where("is_updated = ?", false)
            my_orders.each do |myord|
                puts myord.inspect
                puts "--------------------"
                puts myord.line_items.inspect
                puts "----------------------"
                puts "Fixing for missing line items"
                new_line_items = OrderSize.add_missing_size(myord.line_items.first)
                puts "**********************"
                puts myord.line_items.inspect
                puts "**********************"


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

                temp_tops = nil
                if temp_tops_h != []
                    temp_tops = temp_tops_h.first['value']
                else
                    temp_tops = nil
                end

                temp_sports_jacket_h = my_temp_line_item
                .select { |x| x['name'] == 'sports-jacket'}
                temp_sports_jacket = temp_sports_jacket_h.first['value']

                
                temp_sports_bra = nil
                temp_sports_bra_h = my_temp_line_item
                .select { |x| x['name'] == 'sports-bra' }
                if temp_sports_bra_h != []
                    temp_sports_bra = temp_sports_bra_h.first['value']
                else
                    temp_sports_bra = nil
                end
                
                if temp_tops == nil
                    temp_tops = temp_sports_jacket
                end
                if temp_sports_bra == nil
                    temp_sports_bra = temp_sports_jacket
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

                #Commented out below to remove size break functionality for inventory
                allocate_ok = can_allocate(temp_tops, temp_leggings, temp_sports_bra, two_item_collection)
                puts allocate_ok


                #allocate_ok = true
                if allocate_ok
                    #myord.is_updated = 't'
                    #myord.save!
                    
                    shopify_product_id = myord.line_items.first['shopify_product_id']
                    puts "shopify_product_id = #{shopify_product_id}"
                    new_order_info = UpdatePrepaidConfig.find_by_product_id(shopify_product_id)

                    puts "New order info: #{new_order_info.title}, #{new_order_info.product_collection}, #{new_order_info.product_id}, #{new_order_info.variant_id} "

                    #update the order per ReCharge's rules, delete stuff and add stuff sigh
                    myord.line_items[0].tap {|myh| myh.delete('shopify_variant_id')}
                    myord.line_items[0].tap {|myh| myh.delete('shopify_product_id')}
                    myord.line_items[0].tap {|myh| myh.delete('images')}
                    myord.line_items[0].tap {|myh| myh.delete('tax_lines')}
                    myord.line_items[0]['product_id'] = new_order_info.product_id.to_i
                    myord.line_items[0]['variant_id'] = new_order_info.variant_id.to_i
                    myord.line_items[0]['quantity'] = 1
                    myord.line_items[0]['title'] = new_order_info.title
                    myord.line_items = update_product_collection(myord.line_items, new_order_info.product_collection)

                    #Adding outfit_id key/value pair for Scoutside
                    outfit_id = 999
                    case new_order_info.product_collection
                    when /\s2\sitem/i
                        outfit_id = 4541680418874
                    when /\s3\sitem/i
                        outfit_id = 4541680549946
                    when /\s5\sitem/i
                        outfit_id = 4543652200506
                    else
                        outfit_id = 8888
                    end

                    temp_outfit_id_h = my_temp_line_item.select { |x| x['name'] == 'oufit_id' }
                    if temp_outfit_id_h != []
                        #update the json value with new outfit_id value
                        myord.line_items.first['properties'].map do |myt|
                            if myt['name'] == 'oufit_id'
                                myt['value'] = outfit_id
                            end

                        end

                    else
                        myord.line_items.first['properties'] << {"name" => "outfit_id", "value" => outfit_id}
                    end




                    puts "+++++++++++++++++++++++++++++"
                    puts "Sending to ReCharge:"
                    puts myord.line_items.inspect
                    puts "++++++++++++++++++++++++++++"
                    

                    #Send to Recharge
                    my_data = { "line_items" => myord.line_items }
                    my_update_order = HTTParty.put("https://api.rechargeapps.com/orders/#{myord.order_id}", :headers => @my_change_charge_header, :body => my_data.to_json, :timeout => 80)
                    puts my_update_order.inspect
                    recharge_header = my_update_order.response["x-recharge-limit"]
                    determine_limits(recharge_header, 0.65)
                    if my_update_order.code == 200
                        myord.is_updated = 't'
                        time_updated = DateTime.now
                        time_updated_str = time_updated.strftime("%Y-%m-%d %H:%M:%S")
                        myord.updated_at = time_updated_str
                        myord.save!
                        puts "Updated order id = #{myord.order_id}"
        
                    else
                        puts "WE could not update the order order_id = #{myord.order_id}"
        
                    end

                    
                    

                else
                    puts "Skipping this one, can't allocate"
                end
            end

            puts "All done with orders"
          end

          def setup_update_matching_subscriptions
            puts "Starting"
            PrepaidSubscriptionUpdated.delete_all
            
            ActiveRecord::Base.connection.reset_pk_sequence!('prepaid_subscriptions_updated')


            my_orders = UpdatePrepaidOrder.all
            my_orders.each do |myord|
                my_fixed_info = OrderLineItemFixed.find_by_order_id(myord.order_id)
                my_sub = Subscription.find_by_subscription_id(my_fixed_info.subscription_id)
                if !my_sub.nil?
                    puts my_sub.inspect
                    PrepaidSubscriptionUpdated.create(subscription_id: my_sub.subscription_id, customer_id: my_sub.customer_id, updated_at: my_sub.updated_at, next_charge_scheduled_at: my_sub.next_charge_scheduled_at, product_title: my_sub.product_title, status: my_sub.status, sku: my_sub.sku, shopify_product_id: my_sub.shopify_product_id, shopify_variant_id: my_sub.shopify_variant_id,  raw_line_items: my_sub.raw_line_item_properties, created_at: my_sub.created_at)
                else
                    puts "Can't find matching subscription to update"
                end
                


            end

            puts "All done"


          end

          def fix_one_prepaid_sub(sub)
            puts "Fixing single sub"
            puts sub.inspect
            #fix product_title, product_id, variant_id, sku, leave product_collection alone

            product_information = {}

            case sub.product_title
            when /\s2\sitem/i
                product_information = {"title" => "3 Months - 2 Items", "product_id" => 2506238492730, "variant_id" => 23656253784122, "sku" => "764204763023" }
            when /\s3\sitem/i
                product_information = {"title" => "3 Months - 3 Items", "product_id" => 2209786298426, "variant_id" => 22212749393978, "sku" => "764204317066"}
            when /\s5\sitem/i
                product_information = {"title" => "3 Months - 5 Items", "product_id" => 2209789771834, "variant_id" => 22212763320378, "sku" => "764204317073"}
            
            else
                product_information = {}  
            end

            send_to_recharge = { "sku" => product_information['sku'], "product_title" => product_information['title'], "shopify_product_id" => product_information['product_id'], "shopify_variant_id" => product_information['variant_id'], "properties" => sub.raw_line_items }
            puts "Sending to Recharge:"
            puts "++++++++++++++++++++++++"
            puts send_to_recharge.inspect

            body = send_to_recharge.to_json
            puts body

            #exit
            #Comment out below for dry run
            my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{sub.subscription_id}", :headers => @my_change_charge_header, :body => body, :timeout => 80)
            puts my_update_sub.inspect
            recharge_limit = my_update_sub.response["x-recharge-limit"]
            determine_limits(recharge_limit, 0.65)

          end


          def fix_scoutside_prepaid_subs
            puts "Starting to fix Scoutside prepaid subs"

            num_subs_fix = 0
            mysubs = PrepaidSubscriptionUpdated.all
            mysubs.each do |mysub|
                temp_product_title = mysub.product_title

                if temp_product_title !~ /month/i
                    puts "#{temp_product_title}"
                    num_subs_fix += 1
                    fix_one_prepaid_sub(mysub)

                end

            end
            puts "We have #{num_subs_fix} subs to fix"


          end

          def load_prepaid_subs_config
            PrepaidSubscriptionConfig.delete_all
            ActiveRecord::Base.connection.reset_pk_sequence!('prepaid_subscriptions_config')

            my_products_sql = "select count(id), product_title, shopify_product_id from prepaid_subscriptions_updated group by product_title, shopify_product_id"

            ActiveRecord::Base.connection.execute(my_products_sql).each do |row|
                puts row.inspect
                my_product_collection = "FAIL"
                my_title = row['product_title']

                case my_title
                when /\s2\sitem/i
                    my_product_collection = "Solar Flare - 2 Items"
                when /\s3\sitem/i
                    my_product_collection = "Solar Flare - 3 Items"
                when /\s5\sitem/i
                    my_product_collection = "Solar Flare - 5 Items"
                when "3 MONTHS"
                    my_product_collection = "Solar Flare - 5 Items"
                end

                PrepaidSubscriptionConfig.create(product_title: row['product_title'], shopify_product_id: row['shopify_product_id'], product_collection: my_product_collection)


            end
            prepaid_sub_config = PrepaidSubscriptionConfig.all
            prepaid_sub_config.each do |myc|
                puts myc.inspect
            end
            puts "All done setting up prepaid config table for SUBS!"



            

          end



          def update_prepaid_subs
            puts "starting"



            my_subs = PrepaidSubscriptionUpdated.where(updated: false)
            my_subs.each do |mysub|
                puts mysub.inspect
                product_id = mysub.shopify_product_id
                my_product_collection = PrepaidSubscriptionConfig.find_by_shopify_product_id(mysub.shopify_product_id)
                puts my_product_collection.product_collection
                temp_line_items = mysub.raw_line_items

                

                #Add outfit_id stuff for Scoutside here
                outfit_id = 999
                case my_product_collection.product_collection
                    when /\s2\sitem/i
                        outfit_id = 4541680418874
                    when /\s3\sitem/i
                        outfit_id = 4541680549946
                    when /\s5\sitem/i
                        outfit_id = 4543652200506
                    else
                        outfit_id = 8888
                end

                found_outfit_id = false
                temp_line_items.map do |mystuff|
                    # puts "#{key}, #{value}"
                    if mystuff['name'] == 'product_collection'
                      mystuff['value'] = my_product_collection.product_collection
                      
                    end
                    if mystuff['name'] == "outfit_id"
                        mystuff['value'] = outfit_id
                        found_outfit_id = true
                    end
                end
                
                if found_outfit_id == false
                    temp_line_items << {"name" => "outfit_id", "value" => outfit_id}
                end



                puts "Send to Recharge properties: #{temp_line_items}"
                send_to_recharge = { "properties" => temp_line_items }
                

                body = send_to_recharge.to_json

                my_update_sub = HTTParty.put("https://api.rechargeapps.com/subscriptions/#{mysub.subscription_id}", :headers => @my_change_charge_header, :body => body, :timeout => 80)
                puts my_update_sub.inspect
                recharge_header = my_update_sub.response["x-recharge-limit"]
                determine_limits(recharge_header, 0.65)

                if my_update_sub.code == 200
                    mysub.updated = true
                    time_updated = DateTime.now
                    time_updated_str = time_updated.strftime("%Y-%m-%d %H:%M:%S")
                    mysub.processed_at = time_updated_str
                    mysub.save
                    puts "Updated subscription id #{mysub.subscription_id}"

                else
                    puts "Could not update prepaid subscription!"
                end
                


            end
            puts "All done updating matching subscriptions to prepaid orders!"

          end






          def determine_limits(recharge_header, limit)
            puts "recharge_header = #{recharge_header}"
            my_numbers = recharge_header.split("/")
            my_numerator = my_numbers[0].to_f
            my_denominator = my_numbers[1].to_f
            my_limits = (my_numerator/ my_denominator)
            puts "We are using #{my_limits*100} % of our API calls"
            if my_limits > limit
                puts "Sleeping 10 seconds"
                sleep 10
            else
                puts "not sleeping at all"
            end
        
          end



    end
end