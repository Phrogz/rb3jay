# encoding: utf-8
class MPD::Playlist
	def summary
		{
			'name'  => name,
			'songs' => songs.select(&:time).length,
			'code'  => nil
		}
	end
	def details
		summary.merge( songs:songs.select(&:time).map(&:summary) )
	end
end

class MPD::Song
	def summary
		{
			'file'   => file,
			'title'  => title,
			'artist' => artist,
			'album'  => album,
		}
	end
	def details(user=nil)
		summary.merge({
			'modified'    => modified,
			'track'       => track,
			'genre'       => genre,
			'date'        => date,
			'time'        => time && time.respond_to?(:last) ? time.last : time,
			'composer'    => composer,
			'disc'        => disc,
			'albumartist' => albumartist,
			'bpm'         => bpm,
			'artwork'     => nil     #TODO: extract and store song artwork
		}).delete_if{ |k,v| v.nil? }
	end
	def hash
		file.hash
	end
	def eql?(song2)
		file == song2.file
	end
end
