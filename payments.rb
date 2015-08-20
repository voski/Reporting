class Payments
  include Enumerable

  def each(&block)
    @payments.each do |payment|
      yield payment
    end
  end

  def initialize
    @payments = []
  end

  def total
    map { |payment| payment.payment_amount.to_i }.inject(:+)
  end

  def tax_total
    map { |payment| payment.payment_tax_amount.to_i }.inject(:+)
  end

  def tip_total
    map { |payment| payment.payment_tip_amount.to_i }.inject(:+)
  end

  def service_total
    map { |payment| payment.payment_service_charge_amount.to_i }
    .inject(:+)
  end

  def <<(payment)
    @payments << payment
  end

  def orders
    map { |payment| payment.order_id }
  end


  def render
    puts "Gross Payments "
    print "total = #{total}, "
    print "revenue = #{total - tax_total}, "
    print "tax = #{tax_total}, "
    print "tip = #{tip_total}, "
    print "service charge = #{service_total}, "
    puts "#{count} transactions"
  end

  def columns
    @payments.first.columns
  end
end
