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

desc 'upate orders in Recharge'
task :update_orders do |t|
    FixPrepaidOrders::ChangePrepaid.new.update_prepaid_orders

end



end