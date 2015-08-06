require 'eventmachine'
require 'time'
require 'json'
require 'set'
require 'taglib'

module RB3Jay
	VERSION = "0.0.1"
	def self.start( args )
		require_relative 'models/init'
		EventMachine.run do
			puts "rb3jay starting on port #{args[:port]}" if args[:debug]
			EventMachine.start_server "127.0.0.1", args[:port], self
		end
		trap(:INT) { EventMachine.stop }
		trap(:HUP) { EventMachine.stop }
		trap(:TERM){ EventMachine.stop }
	end

	# ***************************************************************************

	def playlists
		Playlist.order(:name).all.map(&:summary)
	end

	def playlist(name:)
		Playlist[name:name].details
	end

	def makePlaylist(name:, code:nil)
		Playlist.create(name:name, query:code, created:Time.now.utc.iso8601)
		"Created playlist #{name}"
	end

	def songs
		Song.order(:artist,:album,:track,:title).all.map(&:summary)
	end

	def song(id:)
		Song[id].details
	end

	def scan(directory:, andsubdirs:true)
		raise "#{directory.inspect} is not a recognized directory" unless File.exist?(directory) && File.directory?(directory)
		existing_dirs = Set.new Song.select_map(:file)
		Dir.chdir(directory) do
			Dir["#{'**/' if andsubdirs}*.{mp3,m4a,ogg,oga,flac}"].map do |path|
				fullpath = File.join(directory,path)
				unless existing_dirs.include?(fullpath)
					TagLib::FileRef.open(path) do |fileref|
					  unless fileref.null?
					    tag = fileref.tag
							Song.create({
								file: fullpath,
								title: tag.title || File.basename(path).sub(/\.[^.]+$/,''),
								artist: tag.artist,
								album: tag.album,
								year: tag.year==0 ? nil : tag.year,
								track: tag.track,
								genre: tag.genre,
								length: fileref.audio_properties.length,
								added:Time.now.utc.iso8601
							}).tap do |song|
								ext,data = case File.extname(path)
									when '.mp3'
										TagLib::MPEG::File.open(path) do |f|
											if p = f.id3v2_tag.frame_list('APIC').first
												[ p.mime_type.split('/').last, p.picture ]
											end
										end
									when '.m4a'
										TagLib::MP4::File.open(path) do |f|
											if p = mp4.tag.item_list_map['covr'].to_cover_art_list
												[ p.format==TagLib::MP4::CoverArt::JPEG ? 'jpg' : 'png', p.data ]
											end
										end
									# TODO: FLAC
								end
								if data
									if ARGS[:directory]
										imagesdir = File.join(ARGS[:directory],'images')
										imagepath = File.join(imagesdir,"#{song.id}.#{ext}")
										song.update(artwork:imagepath)
										Dir.mkdir(imagesdir) unless File.exist?(imagesdir)
										File.open(imagepath,'wb'){ |f| f<<data }
									else
										song.update(artwork:data)
									end
								end
							end
						end
					end
				end
			end.compact.map(&:summary)
		end
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

