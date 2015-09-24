class Credits
  include Enumerable

  def initialize
    @credits = []
  end

  def each(&block)
    @credits.each do |credit|
      yield credit
    end
  end

  def total
    map { |credit| credit.credit_amount.to_i }.inject(:+)
  end

  def tax_total
    map { |credit| credit.credit_tax_amount.to_i}.inject(:+)
  end

  def service_total
    map { |credit| credit.refund_service_charge_amount }.inject(:+)
  end

  def <<(credit)
    @credits << credit
  end

  def orders
    map { |credit| credit.order_uuid }
  end

  def render
    print "Credits  || "
    print "total = #{cents_to_string total}, "
    print "revenue = #{cents_to_string (total - tax_total)}, "
    print "tax = #{cents_to_string tax_total}, "
    puts "#{count} transactions"
  end

  def columns
    @credits.first.columns
  end

  def cents_to_string cents
    "$#{cents/100}.#{cents%100}"
  end
end
