class Refunds
  include Enumerable

  def initialize
    @refunds = []
  end

  def each(&block)
    @refunds.each do |refund|
      yield refund
    end
  end

  def total
    map { |refund| refund.refund_amount.to_i }.inject(:+)
  end

  def tax_total
    map { |refund| refund.refund_tax_amount.to_i}.inject(:+)
  end

  def service_total
    map { |refund| refund.refund_service_charge_amount }.inject(:+)
  end

  def <<(refund)
    @refunds << refund
  end

  def orders
    map { |refund| credit.order_id }
  end

  def render
    print "Refunds  || "
    print "total = #{cents_to_string total}, "
    print "revenue = #{cents_to_string (total - tax_total)}, "
    print "tax = #{cents_to_string tax_total}, "
    print "service charge = #{cents_to_string service_total}, "
    puts "#{count} transactions"
  end

  def columns
    @refunds.first.columns
  end

  def cents_to_string cents
    "$#{cents/100}.#{cents%100}"
  end
end
