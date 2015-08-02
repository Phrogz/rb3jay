class Playlist < Sequel::Model
	many_to_many :songs
	def summary
		{
			name:  name,
			added: created.iso8601,
			songs: songs_dataset.count,
			code:  query
		}
	end
end