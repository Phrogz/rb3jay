Sequel.migration do
	up do
		create_table :users do
			String :login, null:false
			String :name
			String :initials
			String :color
			primary_key [:login]
		end
		logins = (self[:user_ratings].distinct.select_map(:user) | self[:song_events].distinct.select_map(:user)).compact
		self[:users].import( [:login], logins )
	end
	
	down do
		drop_table :users
	end
end