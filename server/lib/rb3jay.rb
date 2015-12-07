require 'eventmachine'
require 'time'
require 'json'
require 'set'
require 'taglib'
require 'ruby-mpd'

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
			id:      file.gsub(' ','💔'),
			file:    file,
			title:   title,
			artist:  artist,
			album:   album,
			genre:   genre,
			date:    date,
			time:    time,
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
		})
	end
	def hash
		file.hash
	end
	def eql?(song2)
		file == song2.file
	end
end

class RB3Jay < EventMachine::Connection
	VERSION = "0.0.1"
	SONG_ORDER = ->(s){ [
		s.artist ? s.artist.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~",
		s.album  || "~~~~",
		s.track  || 99,
		s.title ? s.title.downcase.sub(/\Athe /,'').gsub(/[^ _a-z0-9]+/,'') : "~~~~"
	]	}
	class << self
		attr_reader :mpd
		def start( args )
			require_relative 'models/init'
			@mpd = MPD.new( args[:mpdhost], args[:mpdport] )
			@mpd.connect
			EventMachine.run do
				puts "rb3jay starting on port #{args[:port]}" if args[:debug]
				EventMachine.start_server "127.0.0.1", args[:port], self
			end
			trap(:INT) { @mpd.disconnect; EventMachine.stop }
			trap(:HUP) { @mpd.disconnect; EventMachine.stop }
			trap(:TERM){ @mpd.disconnect; EventMachine.stop }
		end
	end

	def mpd
		self.class.mpd
	end

	# ***************************************************************************

	def playlists
		mpd.playlists.sort(&:name).map(&:summary)
	end

	def playlist(name:)
		(list=mpd.playlists.find{ |pl| pl.name==name }) && list.details
	end

	def makePlaylist(name:, code:nil)
		MPD::Playlist.new(mpd,name)
		warn "Live playlists not yet supported" if code
		"Created playlist #{name}"
	end

	def songs
		mpd.songs.sort_by(&SONG_ORDER).map(&:summary).uniq
	end

	def search(query:)
		return [] if !query || query.empty?
		query.split(/\s+/).map{ |piece| mpd.where(any:piece) }.inject(:&).uniq.sort_by(&SONG_ORDER).map(&:summary)
	end

	def song(file:)
		(song = mpd.where({file:file},{strict:true}).first) && song.details
	end

	def next
		mpd.next
	end

	def back
		mpd.previous
	end

	def stop
		mpd.pause = true
	end

	def play
		case mpd.status[:state]
		when :pause then mpd.pause = false
		when :stop
			unless mpd.queue(1) # TODO: does queue(1) return nil or [] when empty?
				# TODO: add songs to queue if is empty
			end
			mpd.play
		end
	end

	def update
		mpd.update
	end

	def editPlaylist(name:, newName:nil, code:'-', add:[], remove:[] )
		playlist = Playlist[name:name]
		raise "Cannot find playlist #{name.inspect}" unless playlist

		successMessages = []
		if newName
			playlist.name = newName
			successMessages << "updated name"
		end
		unless code=='-'
			playlist.query = code
			successMessages << "updated code"
		end

		remove = [*remove]
		unless playlist.query || remove.empty?
			removed = ARGS[:db][:playlists_songs].filter( playlist_id:playlist.pk, song_id:remove ).delete
			successMessages << "removed #{removed} song#{:s if removed!=1}"
		end

		add = [*add]
		unless playlist.query || add.empty?
			existing = ARGS[:db][:playlists_songs].filter(playlist_id:playlist.pk).select_map(:song_id)
			new_ids = add - existing
			ARGS[:db][:playlists_songs].import(
				[:playlist_id, :song_id],
				[playlist.pk].product(new_ids)
			)
			successMessages << "added #{new_ids.length} song#{:s if new_ids.length!=1}"
		end

		playlist.save unless successMessages.empty?
		successMessages.join("; ")
	end

	def quit
		puts "rb3jay shutting down..." if ARGS[:debug]
		EventMachine.stop
		nil
	end

	# ***************************************************************************

	def receive_data(data)
		puts "rb3jay received: #{data.inspect}" if ARGS[:debug]
		data.chomp!
		return if data.empty?
		begin
			req = JSON.parse(data)
			return err! "Queries must be JSON Objects" unless req.is_a? Hash
			return err! "No cmd supplied" unless req['cmd']
			cmd = req.delete('cmd').to_s
			return err! "Unsupported cmd #{cmd.inspect}" unless respond_to? cmd
			begin
				keyargs = method(cmd).parameters.map{ |_,name| [name,req[name.to_s]] if req.include?(name.to_s) }.compact.to_h
				result = keyargs.empty? ? send(cmd) : send(cmd,keyargs)
				joy! result unless result.nil?
			rescue Exception => e
				err! "Problem running #{cmd.inspect}", {message:e.message}
			end
		rescue JSON::ParserError => e
			err! "Could not parse: #{data.inspect}", {message:e.message}
		end
	end

	def joy!(result)
		send! ok:true, result:result
	end

	def err!(msg,details=nil)
		result = { ok:false, msg:msg }
		unless details.nil?
			details = {details:details} unless details.is_a? Hash
			result.merge! details
		end
		send! result
	end

	def send!(data)
		puts "rb3jay sending: #{data.to_json}" if ARGS[:debug]
		send_data( data.to_json + "\n" )
	end

end

