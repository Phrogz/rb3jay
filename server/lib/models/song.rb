class Song < Sequel::Model
	many_to_many :playlists

	def summary
		{
			id:      id,
			title:   title,
			artist:  artist,
			artwork: artwork,
			album:   album,
			genre:   genre,
			year:    year,
			length:  length,
			rank:    rank,
		}.delete_if{ |_,v| v.nil? }
	end

	def details
		{
			id:      id,
			title:   title,
			artist:  artist,
			artwork: artwork,
			album:   album,
			genre:   genre,
			year:    year,
			length:  length,
			rank:    rank,

			file:    file,
			artwork: artwork,
			rank:    rank,
			track:   track,
			added:   added,
			bpm:     bpm,
		}.delete_if{ |_,v| v.nil? }
	end

	def rank
		0.5 # TODO
	end
end