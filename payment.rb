require 'byebug'

require 'mysql2'
require_relative 'query.rb'
require_relative 'payments.rb'
require_relative 'refunds.rb'
require_relative 'credits.rb'
require_relative 'sql_object.rb'

def non_uniq_orders collection
  collection.orders.select { |el| collection.orders.count(el) > 1 }
end


payments = Payments.new
refunds = Refunds.new
credits = Credits.new
cash = []
orders = []
tax_total = 0
tip_total = 0
service_total = 0
payment_total = 0

# rs.each_hash do |result|
#   payments << Payment.new(result)
# end
#
# rs = con.query query.refund
# rs.each_hash do |result|
#   refunds << Refund.new(result)
# end
#
# rs = con.query query.credit
# rs.each_hash do |result|
#   credits << Credit.new(result)
# end
#
# rs = con.query query.cash
# rs.each_hash do |result|
#   cash << Cash.new(result)
# end
#
# rs = con.query query.orders(non_uniq_orders(payments).uniq)
# rs.each_hash do |result|
#   orders << Order.new(result)
# end

def line_break
  puts "___________________________________________"
end

def parse_date timestamp
  DateTime.parse(timestamp).strftime('%x %r')
end

def report_info (options={})
  puts "report for merchant_id #{options[:merchant_id]}"
  puts "report starting #{parse_date options[:start_time]}"
  puts "report ending #{parse_date options[:end_time]}"
end

line_break
payments.render

con.close

line_break

puts refunds.render

line_break
puts credits.render

line_break
puts "#num of unique orders for payments #{payments.orders.uniq.count}"

line_break
