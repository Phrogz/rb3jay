# encoding: utf-8
class MPD::Playlist
	def summary
		{
			name:  name,
			songs: songs.length,
			code:  nil
		}
	end
	def details
		summary.merge( songs:songs.map(&:summary) )
	end
end

class MPD::Song
	def summary
		{
			file:    file,
			title:   title,
			artist:  artist,
			album:   album,
			genre:   genre,
			date:    date,
			time:    time && time.respond_to?(:last) ? time.last : time,
			rank:    0.5,    #TODO: calculate song rankings
  		artwork: nil     #TODO: extract and store song artwork
		}
	end
	def details
		summary.merge({
			modified:    modified,
			track:       track,
			composer:    composer,
			disc:        disc,
			albumartist: albumartist,
			bpm:         bpm
		}) #.delete_if{ |k,v| v.nil? }
	end
	def hash
		file.hash
	end
	def eql?(song2)
		file == song2.file
	end
end
