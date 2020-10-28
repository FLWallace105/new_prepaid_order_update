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

            new_end = "2020-10-07"

            #update_prepaid_sql = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders where  orders.is_prepaid = '1'  and orders.scheduled_at > \'#{my_end_month_str}\' and orders.scheduled_at < \'#{new_end}\' and orders.status = \'QUEUED\'  "

            update_prepaid_sql = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders, order_collection_sizes where order_collection_sizes.order_id = orders.order_id and  orders.is_prepaid = '1'  and orders.scheduled_at > \'2020-10-31\' and orders.scheduled_at < \'2020-11-07\' and orders.status = \'QUEUED\' and (order_collection_sizes.product_collection not ilike 'funky%something%'  ) "

            update_for_elliestaging_mix_match = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders, order_collection_sizes where order_collection_sizes.order_id = orders.order_id and  orders.is_prepaid = '1'  and orders.scheduled_at > \'2020-10-19\' and orders.scheduled_at < \'2020-11-01\' and orders.status = \'QUEUED\' and (order_collection_sizes.product_collection not ilike '%some%test%' and  order_collection_sizes.product_collection not ilike '%full%bloom%' ) "

            


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
                #product_information = {"title" => "3 Months - 2 Items", "product_id" => 2168707809331, "variant_id" => 18468097949747, "sku" => "764204317073" }
            when /\s3\sitem/i
                product_information = {"title" => "3 Months - 3 Items", "product_id" => 2209786298426, "variant_id" => 22212749393978}
                #product_information = {"title" => "3 Months - 3 Items", "product_id" => 1421100974131, "variant_id" => 15880479998003, "sku" => "764204317066"}
            when /\s5\sitem/i
                product_information = {"title" => "3 Months - 5 Items", "product_id" => 2209789771834, "variant_id" => 22212763320378}
                #product_information = {"title" => "3 Months - 5 Items", "product_id" => 1635509469235, "variant_id" => 15880480063539, "sku" => "764204317073"}
                #puts "Got a 5 Item"
                
            
            else
                product_information = {}  
            end

            temp_order.line_items[0].tap {|myh| myh.delete('shopify_variant_id')}
            temp_order.line_items[0].tap {|myh| myh.delete('shopify_product_id')}
            temp_order.line_items[0].tap {|myh| myh.delete('images')}
            temp_order.line_items[0].tap {|myh| myh.delete('tax_lines')}
            temp_order.line_items[0].tap {|myh| myh.delete('external_inventory_policy')}

            temp_order.line_items[0]['product_id'] = product_information['product_id']
            temp_order.line_items[0]['variant_id'] = product_information['variant_id']
            temp_order.line_items[0]['quantity'] = 1
            temp_order.line_items[0]['title'] = product_information['title']
            temp_order.line_items[0]['product_title'] = product_information['title']
            temp_order.line_items[0]['sku'] = product_information['sku']


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
                    my_product_collection = "Balanced Beige - 2 Items"
                when /\s3\sitem/i
                    my_product_collection = "Balanced Beige - 3 Items"
                when /\s5\sitem/i
                    my_product_collection = "Balanced Beige - 5 Items"
                when "3 MONTHS"
                    my_product_collection = "Balanced Beige - 5 Items"
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

          def can_allocate(tops, leggings, jacket, two_item)
            tops_avail = false
            leggings_avail = false
            bra_avail = false
            jacket_avail = false
            leggings_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "leggings", leggings).first
            tops_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "tops", tops).first
            jacket_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "sports-jacket", jacket).first

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
                jacket_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "sports-jacket", jacket).first
                if jacket_avail_inventory.inventory_avail > 0
                    jacket_avail = true
                else
                    jacket_avail = false
                end
            else
                #its a two item, we "have" bra size available
                jacket_avail = true
            end

            if tops_avail && leggings_avail && jacket_avail
                leggings_avail_inventory.inventory_avail -= 1
                tops_avail_inventory.inventory_avail -= 1
                leggings_avail_inventory.inventory_assigned += 1
                tops_avail_inventory.inventory_assigned += 1
                leggings_avail_inventory.save!
                tops_avail_inventory.save!
                unless two_item
                    jacket_avail_inventory = OrderUpdatedInventorySize.where("product_type = ? and product_size = ?", "sports-bra", bra).first
                    jacket_avail_inventory.inventory_avail -= 1
                    jacket_avail_inventory.inventory_assigned += 1
                    jacket_avail_inventory.save! 
                else
                    puts "not adjusting jacket inventory as its a two item"
                    
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
                allocate_ok = can_allocate(temp_tops, temp_leggings, temp_sports_jacket, two_item_collection)
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
                    myord.line_items[0].tap {|myh| myh.delete('external_inventory_policy')}
                    myord.line_items[0]['product_id'] = new_order_info.product_id.to_i
                    myord.line_items[0]['variant_id'] = new_order_info.variant_id.to_i
                    myord.line_items[0]['quantity'] = 1
                    myord.line_items[0]['title'] = new_order_info.title
                    myord.line_items = update_product_collection(myord.line_items, new_order_info.product_collection)

                    #Floyd Wallace 10/14/2020
                    #add raw_skus to properties for testing on EllieSTaging.
                    #skus_for_tops = [722457990948, 764204207466, 764204207473, 764204207480, 764204112531, 764204099450, 764204099467, 764204099474, 764204099481, 764204112548, 764204099535, 764204099542, 764204099559, 764204099566].sample
                    #skus_for_leggings = [764204295937, 764204295944, 764204295951, 764204295968, 764204296088, 764204296095, 764204296101, 764204296118, 764204295982, 764204295999, 764204296002, 764204296019].sample
                    #skus_for_bras = [722457854059, 722457854066, 722457854073, 722457854080, 764204475001, 764204475018, 764204475025, 764204475032, 764204475049, 764204126927, 764204126934, 764204126941, 764204126958, 764204126965].sample
                    #skus_for_accessories = [722457706419, 722457833986, 764204325917, 764204368143, 764204380930, 722457921331, 764204242665, 764204243839].sample
                    #skus_for_equipment = [745934207032, 764204359745, 764204134199, 764204376841, 764204243822, 764204241460, 731899210309, 764204161799].sample

                   # mylist = ""


                   # case myord.line_items[0]['title']
                   #     when /\s2\sitem/i
                   #         mylist = "#{skus_for_tops}, #{skus_for_leggings}"
                   #     when /\s3\sitem/i
                   #         mylist = "#{skus_for_tops}, #{skus_for_leggings}, #{skus_for_bras}"
                   #     when /\s5\sitem/i
                   #         mylist = "#{skus_for_tops}, #{skus_for_leggings}, #{skus_for_bras}, #{skus_for_accessories}, #{skus_for_equipment}"
                    #    when "3 MONTHS"
                    #        mylist = "#{skus_for_tops}, #{skus_for_leggings}, #{skus_for_bras}, #{skus_for_accessories}, #{skus_for_equipment}"
                    #    else
                    #        mylist = "#{skus_for_tops}, #{skus_for_leggings}, #{skus_for_bras}, #{skus_for_accessories}, #{skus_for_equipment}"
                    #end




                    #myord.line_items[0]['properties'] << { "name" => "raw_skus", "value" => mylist}





                    #Adding outfit_id key/value pair for Scoutside
                    #outfit_id = 999
                    #case new_order_info.product_collection
                    #when /\s2\sitem/i
                    #    outfit_id = 4541684613178
                    #when /\s3\sitem/i
                    #    outfit_id = 4541684744250
                    #when /\s5\sitem/i
                    #    outfit_id = 4541685858362
                    #else
                    #    outfit_id = 8888
                    #end

                    #temp_outfit_id_h = my_temp_line_item.select { |x| x['name'] == 'oufit_id' }
                    #if temp_outfit_id_h != []
                        #update the json value with new outfit_id value
                    #    myord.line_items.first['properties'].map do |myt|
                    #        if myt['name'] == 'oufit_id'
                    #            myt['value'] = outfit_id
                    #         end

                    #    end

                    #else
                    #    myord.line_items.first['properties'] << {"name" => "outfit_id", "value" => outfit_id}
                    #end




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
                #product_information = {"title" => "3 Months - 2 Items", "product_id" => 2506238492730, "variant_id" => 23656253784122, "sku" => "764204763023" }
                product_information = {"title" => "3 Months - 2 Items", "product_id" => 2168707809331, "variant_id" => 18468097949747, "sku" => "764204317073" }

            when /\s3\sitem/i
                #product_information = {"title" => "3 Months - 3 Items", "product_id" => 2209786298426, "variant_id" => 22212749393978, "sku" => "764204317066"}
                product_information = {"title" => "3 Months - 3 Items", "product_id" => 1421100974131, "variant_id" => 15880479998003, "sku" => "764204317066"}
            when /\s5\sitem/i
                #product_information = {"title" => "3 Months - 5 Items", "product_id" => 2209789771834, "variant_id" => 22212763320378, "sku" => "764204317073"}
                {"title" => "3 Months - 5 Items", "product_id" => 1635509469235, "variant_id" => 15880480063539, "sku" => "764204317073"}
            
            else
                product_information = {}  
            end

            send_to_recharge = { "sku" => product_information['sku'], "product_title" => product_information['title'], "shopify_product_id" => product_information['product_id'], "shopify_variant_id" => product_information['variant_id'], "properties" => sub.raw_line_item_properties }
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

            #num_subs_fix = 0
            #mysubs = PrepaidSubscriptionUpdated.all
            #mysubs.each do |mysub|
            #    temp_product_title = mysub.product_title

            #    if temp_product_title !~ /month/i
            #        puts "#{temp_product_title}"
            #        num_subs_fix += 1
            #        fix_one_prepaid_sub(mysub)

           #     end

           # end
          #  puts "We have #{num_subs_fix} subs to fix"

          #New Approach use subscriptions with mismatch in is_prepaid attribute and product_title
          my_bad_subs = Subscription.where("is_prepaid = ? and product_title not ilike '3%month%' ", true)
          num_bad_subs = my_bad_subs.count
          puts "Fixing #{num_bad_subs} bad prepaid subs"

          PrepaidSubscriptionUpdated.delete_all
            
          ActiveRecord::Base.connection.reset_pk_sequence!('prepaid_subscriptions_updated')
          
          my_bad_subs.each do |mybad|
            puts mybad.subscription_id
            PrepaidSubscriptionUpdated.create(subscription_id: mybad.subscription_id, customer_id: mybad.customer_id, updated_at: mybad.updated_at, next_charge_scheduled_at: mybad.next_charge_scheduled_at, product_title: mybad.product_title, status: mybad.status, sku: mybad.sku, shopify_product_id: mybad.shopify_product_id, shopify_variant_id: mybad.shopify_variant_id,  raw_line_items: mybad.raw_line_item_properties, created_at: mybad.created_at)

            fix_one_prepaid_sub(mybad)

          end



          end

          def check_child_orders_fixed_subs
            puts "Checking child orders for subs"

            my_prepaid_subs = PrepaidSubscriptionUpdated.all
            my_prepaid_subs.each do |myp|
                temp_customer = myp.customer_id
                puts "customer id #{temp_customer} - subscription_id: #{myp.subscription_id}"
                my_orders = Order.where("customer_id = ? and is_prepaid = ? and scheduled_at > '2020-09-30' and scheduled_at < '2020-11-01' ", temp_customer, "1")
                puts "------"
                my_orders.each do |myord|
                    puts myord.inspect
                    puts "**********"
                    temp_line_items = myord.line_items.first
                    #puts temp_line_items.inspect
                    puts "#{temp_line_items['title']}, #{temp_line_items['product_title']}, #{temp_line_items['price']}, #{temp_line_items['properties']}"
                end
                puts "------"


            end


          end


          def scoutside_subs_check_product_collection
            puts "Starting check ..."
            my_temp = PrepaidSubscriptionUpdated.all

            num_bad_collections = 0

            my_temp.each do |myt|
                puts myt.subscription_id
                #puts myt.raw_line_items.inspect
                prod_coll = myt.raw_line_items.select{ |x| x['name'] == 'product_collection'}
                #puts prod_coll.inspect
                #puts prod_coll.first['value']
                temp_prod_coll = prod_coll.first['value']
                if ( temp_prod_coll =~ /urban/i || temp_prod_coll =~ /free/i || temp_prod_coll =~ /solar/i || temp_prod_coll =~ /lunar/i  || temp_prod_coll =~ /heart\sfelt/i || temp_prod_coll =~ /chill/i  || temp_prod_coll =~ /press/i  || temp_prod_coll =~ /wine\snot/i  || temp_prod_coll =~ /pacific\screst/i  || temp_prod_coll =~ /mint\scondition/i  || temp_prod_coll =~ /laguna/i )
                puts "collection OK"
                puts "Deleting sub out of table"
                myt.delete

                else
                    puts "collection not OK"
                    puts temp_prod_coll
                    num_bad_collections += 1
                end

            end
            puts "We have #{num_bad_collections} bad collections"

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
                    my_product_collection = "Mix and Match - 2 Items"
                when /\s3\sitem/i
                    my_product_collection = "Mix and Match - 3 Items"
                when /\s5\sitem/i
                    my_product_collection = "Mix and Match - 5 Items"
                when "3 MONTHS"
                    my_product_collection = "Mix and Match - 5 Items"
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
                #outfit_id = 999
                #case my_product_collection.product_collection
                #    when /\s2\sitem/i
                #        outfit_id = 4541684613178
                #    when /\s3\sitem/i
                #        outfit_id = 4541684744250
                #    when /\s5\sitem/i
                #        outfit_id = 4541685858362
                #    else
                #        outfit_id = 8888
                #end

                #found_outfit_id = false
                temp_line_items.map do |mystuff|
                    # puts "#{key}, #{value}"
                    if mystuff['name'] == 'product_collection'
                      mystuff['value'] = my_product_collection.product_collection
                      
                    end
                    #if mystuff['name'] == "outfit_id"
                    #    mystuff['value'] = outfit_id
                    #    found_outfit_id = true
                    #end
                end
                
                #if found_outfit_id == false
                #    temp_line_items << {"name" => "outfit_id", "value" => outfit_id}
                #end

                my_sql = "select order_line_items_fixed.order_id from order_line_items_fixed, update_prepaid where order_line_items_fixed.subscription_id = \'#{mysub.subscription_id}\' and order_line_items_fixed.order_id = update_prepaid.order_id"

                my_result = ActiveRecord::Base.connection.execute(my_sql).values.first.first
                puts my_result.inspect
                my_order = UpdatePrepaidOrder.find_by_order_id(my_result)
                puts my_order.line_items[0]['properties'].inspect
                my_raw_skus_temp = my_order.line_items[0]['properties'].select { |x| x['name'] == 'raw_skus'}
                puts my_raw_skus_temp
                
                



                temp_line_items << my_raw_skus_temp.first



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
                #exit


            end
            puts "All done updating matching subscriptions to prepaid orders!"

          end

          def setup_fix_prepaid_orders_missing_price
            update_prepaid_sql = "insert into update_prepaid (order_id, transaction_id, charge_status, payment_processor, address_is_active, status, order_type, charge_id, address_id, shopify_id, shopify_order_id, shopify_cart_token, shipping_date, scheduled_at, shipped_date, processed_at, customer_id, first_name, last_name, is_prepaid, created_at, updated_at, email, line_items, total_price, shipping_address, billing_address, synced_at) select orders.order_id, orders.transaction_id, orders.charge_status, orders.payment_processor, orders.address_is_active, orders.status, orders.order_type, orders.charge_id, orders.address_id, orders.shopify_id, orders.shopify_order_id, orders.shopify_cart_token, orders.shipping_date, orders.scheduled_at, orders.shipped_date, orders.processed_at, orders.customer_id, orders.first_name, orders.last_name, orders.is_prepaid, orders.created_at, orders.updated_at, orders.email, orders.line_items, orders.total_price, orders.shipping_address, orders.billing_address, orders.synced_at from orders, order_line_items_fixed where order_line_items_fixed.order_id = orders.order_id and orders.is_prepaid = '1' and orders.scheduled_at > '2020-10-05' and order_line_items_fixed.is_line_item_price_present = 'f' and orders.status = 'QUEUED' "

            


            UpdatePrepaidOrder.delete_all
            
            ActiveRecord::Base.connection.reset_pk_sequence!('update_prepaid')
            ActiveRecord::Base.connection.execute(update_prepaid_sql)
            puts "Done"


          end

          def update_broken_price_prepaid_orders
            puts "Starting update prepaid orders broken price"

            num_missing_subs = 0
            num_non_matching_product_title = 0

            column_header = ["order_id", "transaction_id", "charge_status", "payment_processor", "address_is_active", "status", "order_type", "charge_id", "address_id", "shopify_id", "shopify_order_id", "shopify_cart_token", "shipping_date", "scheduled_at", "shipped_date", "processed_at", "customer_id", "first_name", "last_name", "is_prepaid", "created_at", "updated_at", "email", "total_price", "line_items"]

            File.delete('prepaid_order_missing_sub.csv') if File.exist?('prepaid_order_missing_sub.csv')
            CSV.open('prepaid_order_missing_sub.csv','a+', :write_headers=> true, :headers => column_header) do |hdr|
            column_header = nil

            
            my_orders = UpdatePrepaidOrder.where("is_updated = ?", false)
            my_orders.each do |myord|
                puts myord.inspect
                customer_id = myord.customer_id
                line_items = myord.line_items
                product_title = ""
                puts "-------------------"
                puts "Customer_id = #{customer_id}, line_items = #{line_items}"
                my_subscriptions = Subscription.find_by_customer_id(customer_id)
                #puts my_subscriptions.inspect
                if !my_subscriptions.nil?
                    puts my_subscriptions.inspect
                    product_title = my_subscriptions.product_title
                    if product_title =~ /3\smonth/i
                        puts "Found matching product title to get valid subscription id"
                        #In here add missing subscription_id and price.
                        my_subscription_id = my_subscriptions.subscription_id
                        puts "****************"
                        puts line_items.inspect
                        puts "****************"
                        shopify_product_id = line_items[0]['shopify_product_id']
                        shopify_variant_id = line_items[0]['shopify_variant_id']
                        myord.line_items[0].tap {|myh| myh.delete('shopify_variant_id')}
                        myord.line_items[0].tap {|myh| myh.delete('shopify_product_id')}
                        myord.line_items[0].tap {|myh| myh.delete('images')}
                        myord.line_items[0].tap {|myh| myh.delete('tax_lines')}
                        myord.line_items[0]['product_id'] = shopify_product_id.to_i
                        myord.line_items[0]['variant_id'] = shopify_variant_id.to_i
                        myord.line_items[0]['price'] = "0.00"
                        myord.line_items[0]['subscription_id'] = my_subscription_id.to_i
                        puts "After Changes:"
                        puts "@@@@@@@@@@@@@@@@@@@@@@@"
                        puts line_items.inspect
                        puts "@@@@@@@@@@@@@@@@@@@@@@@"

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
                        num_non_matching_product_title += 1
                    end
                else
                    puts "Nil subscription"
                    num_missing_subs += 1
                    
                    csv_data_out = [myord.order_id, myord.transaction_id, myord.charge_status, myord.payment_processor, myord.address_is_active, myord.status, myord.order_type, myord.charge_id, myord.address_id, myord.shopify_id, myord.shopify_order_id, myord.shopify_cart_token, myord.shipping_date, myord.scheduled_at, myord.shipped_date, myord.processed_at, myord.customer_id, myord.first_name, myord.last_name, myord.is_prepaid, myord.created_at, myord.updated_at, myord.email, myord.total_price, myord.line_items]
                    hdr << csv_data_out
                end

            end
        end
        #end of csv part
            puts "We have #{num_missing_subs} orders with missing subscription info"
            puts "We have #{num_non_matching_product_title} orders where we cannot match product_title"


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