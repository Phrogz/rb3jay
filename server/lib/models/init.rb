require 'sequel'

Sequel.extension :migration
ARGS[:db] = ARGS[:nodb] ? Sequel.sqlite : Sequel.sqlite
Sequel::Migrator.run ARGS[:db], File.expand_path('../migrations',__FILE__)

require_relative 'song'
require_relative 'playlist'
