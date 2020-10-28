require 'dotenv'
Dotenv.load
require 'active_record'
require 'resque'
require 'resque/tasks'
require 'sinatra/activerecord/rake'
require_relative 'update_prepaid_orders'


namespace :order_update do
desc 'setup prepaid orders'
task :setup_prepaid_orders do |t|
    
    FixPrepaidOrders::ChangePrepaid.new.setup_prepaid_orders
end

desc 'setup prepaid config table'
task :setup_prepaid_config do |t|
    FixPrepaidOrders::ChangePrepaid.new.setup_prepaid_config

end

desc 'setup inventory size breaks table'
task :setup_inventory_size_breaks do |t|
    FixPrepaidOrders::ChangePrepaid.new.load_inventory_sizes

end

desc 'setup parent prepaid subscriptions to be update to match orders'
task :setup_parent_prepaid_subs do |t|
    FixPrepaidOrders::ChangePrepaid.new.setup_update_matching_subscriptions
end

desc 'setup parent prepaid subs CONFIG info for updating subs'
task :setup_subs_config_info do |t|
    FixPrepaidOrders::ChangePrepaid.new.load_prepaid_subs_config
end

desc 'upate orders in Recharge'
task :update_orders do |t|
    FixPrepaidOrders::ChangePrepaid.new.update_prepaid_orders

end

desc 'update parent prepaid subs to match orders in ReCharge'
task :update_parent_subs do |t|
    FixPrepaidOrders::ChangePrepaid.new.update_prepaid_subs
end

desc 'clean up orders messed up by Scoutside'
task :cleanup_scoutside_orders do |t|
    FixPrepaidOrders::ChangePrepaid.new.cleanup_scoutside_orders
end

desc 'cleanup parent prepaid subs messed up by Scoutside'
task :cleanup_scoutside_prepaid_subs do |t|
    FixPrepaidOrders::ChangePrepaid.new.fix_scoutside_prepaid_subs

end

desc 'check on scoutside bad subs product_collection properties'
task :check_scoutside_subs_properties do |t|
    FixPrepaidOrders::ChangePrepaid.new.scoutside_subs_check_product_collection
end

desc 'check child orders from fixed scoutside subs'
task :check_child_orders_from_subs do |t|
    FixPrepaidOrders::ChangePrepaid.new.check_child_orders_fixed_subs
end

desc 'setup prepaid orders with missing price'
task :setup_prepaid_orders_missing_price do |t|
    FixPrepaidOrders::ChangePrepaid.new.setup_fix_prepaid_orders_missing_price
end

desc 'fix broken price orders also subscription id info'
task :fix_broken_price_orders do |t|
    FixPrepaidOrders::ChangePrepaid.new.update_broken_price_prepaid_orders

end



end