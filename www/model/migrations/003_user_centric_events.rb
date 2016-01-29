Sequel.migration do
	change do
		alter_table :song_events do
			add_column :user, String, default:nil
			add_index [:user,:when]
		end
	end
end