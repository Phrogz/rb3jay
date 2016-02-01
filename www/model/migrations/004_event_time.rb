Sequel.migration do
	change do
		alter_table :song_events do
			add_column :duration, Integer, default:nil
		end
	end
end