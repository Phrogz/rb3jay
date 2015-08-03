class Song < Sequel::Model
	many_to_many :playlists
	def summary
		{
			id:     id,
			title:  title,
			artist: artist,
			album:  album,
			genre:  genre,
			year:   year,
			rank:   rank
		}.delete_if{ |_,v| v.nil? }
	end

	def rank
		# TODO
		0.5
	end
end