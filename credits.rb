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
    puts "Gross Credits "
    print "total = #{total}, "
    print "revenue = #{total - tax_total}, "
    print "tax = #{tax_total}, "
    puts "#{count} transactions"
  end

  def columns
    @credits.first.columns
  end
end
