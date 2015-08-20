require 'byebug'
require 'Mysql'
require 'mysql2'
require 'active_record'
require_relative 'query.rb'
require_relative 'payments.rb'
require_relative 'refunds.rb'
require_relative 'credits.rb'
require_relative 'sql_object.rb'


options = {
  merchant_id: 1027,
  start_time: '2015-05-08 00:00:00',
  end_time: '2015-08-01 23:59:59'
}


client = Mysql2::Client.new(host: "localhost", username: "root")

def get_tables_from_db(client, db)
    map = {}

    client.query("use #{db}")
    tables = client.query("show tables")

    tables.each do |row|
      val = row.values.first
      map[val] = "#{db}.#{val}"
    end

   map
end


order_tables = get_tables_from_db(client, "orders")
meta_tables = get_tables_from_db(client, "meta")

query = Query.new(options, order_tables.merge(meta_tables))

results = client.query(query.payments_from_narb)

payments_report = client.query(query.payment_sql)
payments_regular_join = client.query(query.payments_regular_join)

puts "count: " + results.count.to_s
puts payments_report.count == payments_regular_join.count
debugger
def non_uniq_orders collection
  collection.orders.select { |el| collection.orders.count(el) > 1 }
end

con = Mysql.new('localhost', 'root', '')
con.select_db('meta')

# rs = con.query query.payment
payments = Payments.new
refunds = Refunds.new
credits = Credits.new
cash = []
orders = []
tax_total = 0
tip_total = 0
service_total = 0
payment_total = 0
#
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
