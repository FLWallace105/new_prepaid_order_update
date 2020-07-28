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



end