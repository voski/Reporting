class SQLObject
  def initialize (params = {})
    params.each do |key, value|
      attributes[key.to_sym] = value
    end

    finalize!
  end

  def attributes
    @attributes ||= {}
  end

  def columns
    attributes.keys
  end

  def finalize!
    columns.each do |col_sym|
      self.class.send(:define_method, "#{col_sym.to_s}", Proc.new { attributes[col_sym] } )
      self.class.send(:define_method, "#{col_sym.to_s}=", Proc.new { |val| attributes[col_sym] = val } )
    end
  end
end

class Payment < SQLObject
end

class Refund < SQLObject
end

class Credit < SQLObject
end

class Cash < SQLObject
end

class Order < SQLObject
end
