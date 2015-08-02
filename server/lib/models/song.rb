class Song < Sequel::Model
	many_to_many :songs
end