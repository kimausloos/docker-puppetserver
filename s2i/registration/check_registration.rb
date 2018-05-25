#!/usr/bin/ruby
STDOUT.sync = true
require 'rubygems'
require 'mysql'
require 'optparse'
require 'yaml'

def quote (str)
  str.gsub(/\\|'/) { |c| "\\#{c}" }
end

hostname = ARGV[0]
DEFAULT_CREDENTIALS = YAML::load( File.open('/certs/registration_credentials.yaml'))

@mysql = {
  :host   => DEFAULT_CREDENTIALS['mysql_host'],
  :user   => DEFAULT_CREDENTIALS['mysql_user'],
  :passwd => DEFAULT_CREDENTIALS['mysql_passwd'],
  :db     => DEFAULT_CREDENTIALS['mysql_db'],
  :port   => DEFAULT_CREDENTIALS['mysql_port'],
  :flag   => DEFAULT_CREDENTIALS['mysql_flag'],
}

puts "Initialising MySQL connection"
begin
  @connection = Mysql.real_connect(@mysql[:host],@mysql[:user],@mysql[:passwd],@mysql[:db])
rescue Mysql::Error => e
  puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
end

time = Time.new()
timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
puts 'Time of processing: ' + timestamp.to_s

registration_check = @connection.query('SELECT hostname,allowed FROM registrations WHERE hostname = "' + hostname + '" AND allowed = true LIMIT 1')

if registration_check.num_rows > 0
  registration_result = registration_check.fetch_hash

  if registration_result['allowed'].to_i == 1
    returncode = 0
    returnmsg = 'allowed'
    registration_check = @connection.query('UPDATE registrations set sign_time = "' + timestamp + '", signed = true WHERE hostname = "' + hostname + '" AND allowed = true LIMIT 1')
  else
    returncode = 1
    returnmsg = 'denied'
  end
else
  returncode = 1
  returnmsg = 'denied'
end

puts 'Registration attempt from ' + hostname + ' ' + returnmsg
@connection.close

exit(returncode)
