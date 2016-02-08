Sequel.migration do
	change do
		alter_table :users do
			add_column :active, TrueClass, default:false
		end
	end
end