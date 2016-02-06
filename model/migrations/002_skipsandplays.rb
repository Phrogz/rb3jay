Sequel.migration do
	change do
		create_table :song_events do
			String :uri,   null:false
			String :event, null:false
			Time   :when,  null:false
			primary_key [:uri,:when]
		end
	end
end