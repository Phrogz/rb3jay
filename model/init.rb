class RB3Jay
	def connect_to sticker_db
		Sequel.extension :migration
		Sequel.connect(adapter:'sqlite', database:sticker_db).tap do |db|
			Sequel::Migrator.run( db, File.expand_path('migrations',__dir__), use_transactions:true)
		end
	end
end