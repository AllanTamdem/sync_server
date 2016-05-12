require 'yaml'

environment = ARGV[0]
mongodb = ARGV[1]

mongoid_config = YAML.load_file "/syncserver/config/mongoid.yml"

mongoid_config[environment]['sessions']['default']['hosts'] = [mongodb]

p "mongoid_config[#{environment}]['sessions']['default']['hosts'] = [#{mongodb}]"

File.open('/syncserver/config/mongoid.yml', 'w') {|f| f.write mongoid_config.to_yaml }