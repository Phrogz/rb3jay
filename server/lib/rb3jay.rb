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

	def makePlaylist(name:, code:nil)
		Playlist.create(name:name, query:code, created:Time.now.utc.iso8601)
		"Created playlist #{name}"
	end

	def songs
		Song.order(:artist,:album,:track,:title).all.map(&:summary)
	end

	def scan(directory:, andsubdirs:true)
		raise "#{directory.inspect} is not a recognized directory" unless File.exist?(directory) && File.directory?(directory)
		existing_dirs = Set.new Song.select_map(:file)
		Dir.chdir(directory) do
			Dir["#{'**/' if andsubdirs}*.{mp3,m4a,ogg}"].map do |path|
				# TODO: validate file as valid audio
				fullpath = File.join(directory,path)
				unless existing_dirs.include?(fullpath)
					TagLib::FileRef.open(path) do |fileref|
					  unless fileref.null?
					    tag = fileref.tag
							Song.create({
								file: fullpath,
								title: tag.title,
								artist: tag.artist,
								album: tag.album,
								year: tag.year==0 ? nil : tag.year,
								track: tag.track,
								genre: tag.genre,
								length: fileref.audio_properties.length,
								added:Time.now.utc.iso8601
							})
						end
					end
				end
			end.compact.map(&:summary)
		end
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

