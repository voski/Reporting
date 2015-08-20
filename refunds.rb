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
    puts "Gross Refunds "
    print "total = #{total}, "
    print "revenue = #{total - tax_total}, "
    print "tax = #{tax_total}, "
    print "service charge = #{service_total}, "
    puts "#{count} transactions"
  end

  def columns
    @refunds.first.columns
  end
end
