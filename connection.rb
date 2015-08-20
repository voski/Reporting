require 'Mysql'

def Connection
  attr_accessor :connection
  
  @connection = Mysql.new('localhost', 'root', '')
  @connection.select_db('cos')
end
