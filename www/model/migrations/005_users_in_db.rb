# Sequel.migration do
# 	up do
# 		create_table :users do
# 			String :login, null:false
# 			String :name
# 			String :initials
# 			primary_key [:login]
# 		end
# 		existing = self[:user_ratings].distinct.select_map([:user]) | self[:song_events].distinct.select_map([:user])
# 		self[:users].insert([:login],existing)
# 	end
# end