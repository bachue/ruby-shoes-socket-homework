#encoding: utf-8

require 'socket'
require 'json'
require 'digest/sha1'

class Server
	def initialize(port)
		@server_socket = UDPSocket.new
		@server_socket.bind nil, port
		@sessions = {}
		puts "Server bind on port #{port}"
	end

	def run
		while 1
			data, addr, port, name = waiting_for_reading
			begin
				data_json = JSON.parse data
				result = nil
				if (username = data_json['username']) && (password = data_json['password'])
					if validate username, password
						sha1 = Digest::SHA1.hexdigest(Time.now.to_s)
						@sessions[sha1] = username
						result = {success: true, message: 'login successfully', session_id: sha1}
					else
						result = {success: false, message: 'Incorrect username/password combination'}
					end
				elsif (data = data_json['data']) && (session_id = data_json['session_id'])
					if @sessions[session_id]
						if data.downcase == 'quit'
							result = {success: true, message: "#{@sessions[session_id]}: bye"}
							@sessions.delete data_json['session_id']
						else
							result = {success: true, message: "#{@sessions[session_id]}: #{data.reverse}"}
						end
					else
						result = {success: false, message: 'Login first'}
					end
				else
					result = {success: false, message: 'Unknown request'}
				end
			rescue
				STDERR.puts "Error: #{$!}"
				result = {success: false, message: 'Server Error'}
			ensure
				begin
					@server_socket.send result.to_json, 0, addr, port
					puts "reply: #{result.inspect}"
				rescue
				end
			end
		end
	end

	private

		def waiting_for_reading
			begin
				request, address = @server_socket.recvfrom 4096
				return request, address[3], address[1], address[2]
			rescue Interrupt
				puts 'exit'
				exit
			end
		end

		def validate(username, password)
			File.open('users.list', 'r') do |file|
				while line = file.gets
					combination = line.chop.split /\s*:\s*/
					raise 'database file damaged' unless combination.length == 2
					return true if combination[0] == username && combination[1] == password
				end
			end
			false
		end
end

Server.new(ARGV[0] || 8001).run
