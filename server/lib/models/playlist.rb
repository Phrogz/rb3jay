class Playlist < Sequel::Model
	many_to_many :songs, order:[:artist,:album,:track,:title]
	def summary
		{
			name:  name,
			added: created.iso8601,
			songs: songs_dataset.count,
			code:  query
		}
	end
	def details
		summary.merge(songs:songs.map(&:summary))
	end
end