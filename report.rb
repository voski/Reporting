require 'byebug'
require 'mysql2'
require_relative 'sql_object.rb'
require_relative 'payments.rb'

require_relative 'clover_client.rb'

report_options = {
  merchant_id: 1027,
  start_time: '2015-05-21 00:00:00',
  end_time: '2015-08-21 23:59:59'
}


class Report
  attr_reader :queries

  def initialize report_options
    @client = CloverClient.new()
    @queries = Query.new(report_options, @client.db_map)
  end

  def execute sql
    @client.execute sql
  end

  def payments
    @payments ||= build_payments
  end

  def build_payments
    payments = Payments.new()
    get_payments.each do |payment|
      payments << Payment.new(payment)
    end

    payments
  end

  def get_payments
    execute(@queries.payment_sql)
  end

end

$report = Report.new(report_options)

# order_tables = map_tables(sql_client, "orders")
# meta_tables = map_tables(sql_client, "meta")
# table_map = order_tables.merge(meta_tables)
