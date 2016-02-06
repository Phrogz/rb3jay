Sequel.migration do
	change do
    create_table :user_ratings do
    	String :user,   null:false
    	String :uri,    null:false
    	String :rating, null:false
    	Time   :when,   null:false
    	primary_key [:user,:uri]
    end
  end
end
