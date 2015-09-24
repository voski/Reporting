require 'byebug'
require 'mysql2'
require_relative 'sql_object.rb'
require_relative 'payments.rb'
require_relative 'refunds.rb'
require_relative 'credits.rb'

require_relative 'clover_client.rb'

report_options = {
  merchant_id: 1417,
  start_time: '2015-08-31 00:00:00',
  end_time: '2015-08-31 23:59:59'
}

class Report
  attr_reader :queries, :payments

  def initialize report_options
    @options = report_options
    @client = CloverClient.new()
    @queries = Query.new(report_options, @client.db_map)
  end

  def execute sql
    @client.execute sql
  end

  def payments
    @payments ||= build_payments
  end

  def refunds
    @refunds ||= build_refunds
  end

  def credits
    @credits ||= build_credits
  end

  def build_payments
    payments = Payments.new()
    get_payments.each do |payment|
      payments << Payment.new(payment)
    end

    payments
  end

  def build_refunds
    refunds = Refunds.new()
    get_refunds.each do |refund|
      refunds << Refund.new(refund)
    end

    refunds
  end

  def build_credits
    credits = Credits.new()
    get_credits.each do |credit|
      credits << Credit.new(credit)
    end

    credits
  end

  def get_payments
    execute(@queries.payment_sql)
  end

  def get_refunds
    execute(@queries.refund_sql)
  end

  def get_credits
    execute(@queries.credit_sql)
  end

  def render
    puts line_break
    puts report_info
    puts line_break
    payments.render
    # refunds.render
    # credits.render
  end

  def report_info
    string = "Report for merchant with id #{@options[:merchant_id]}"
    string += " from #{@options[:start_time]} to #{@options[:end_time]}"
  end

  def line_break length=80
    string = ""
    length.times do
      string += "-"
    end
    string
  end
end


$report = Report.new(report_options)
# $report.render

result = $report.execute($report.queries.not_null_receipts)
# puts result.entries
# puts result.entries.map { |e| e["unit_price"] * e["qty"]}.inject(:+)
