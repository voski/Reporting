require 'mysql2'
require_relative 'query.rb'

class CloverClient
  attr_reader :client, :db_map

  def initialize (options={})
    defaults = {databases: %w(orders meta)}
    options = defaults.merge(options)
    @client = open_connection(options)
    @db_map = map_tables(@client, options[:databases])
  end

  def map_tables(client, databases)
    map = {}
    databases.each do |db_name|
      map.merge!(map_database_table(client, db_name))
    end
    map
  end

  def map_database_table(client, db_name)
      map = {}
      client.query("USE #{db_name}")
      tables_result = client.query("SHOW TABLES")

      tables_result.each do |entry|
        table_name = entry.values.first
        map[table_name] = "#{db_name}.#{table_name}"
      end

     map
  end

  def execute sql
    @client.query(sql)
  end

  def close
    @client.close
  end

  def open_connection (options={})
    defaults = {host: "localhost", username: "root"}
    options = defaults.merge(options)
    Mysql2::Client.new(host: options[:host], username: options[:username])
  end


end
