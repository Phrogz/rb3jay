Sequel.migration do
	change do
    create_table :user_playlist_songs do
    	String :user_id, null:false
    	String :uri,     null:false
    	Fixnum :index,  null:false
    	primary_key [:user_id,:uri]
    end
  end
end
