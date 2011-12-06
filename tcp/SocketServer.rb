#encoding: utf-8

require 'socket'
require 'json'
require 'digest/sha1'

class Server
	def initialize(port)
		@server_socket = TCPServer.open port
		@server_socket.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
		@descriptors = [@server_socket]
		@sessions = {}
		puts "Server started on port #{port}"
	end

	def run
		while 1
			ready = waiting_for_reading
			readable = ready[0]
			for sock in readable
				if sock == @server_socket
					accept_sock
				elsif sock.eof?
					delete_sock sock
				else
					begin
						data_json = JSON.parse sock.gets
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
							sock.puts result.to_json
							puts "reply: #{result.inspect}"
						rescue
						end
					end
				end
			end
		end
	end

	private

		def waiting_for_reading
			begin
				select @descriptors
			rescue Interrupt
				puts 'exit'
				exit
			end
		end

		def accept_sock
			new_sock = @server_socket.accept
			@descriptors << new_sock
			puts "Connection Success: #{new_sock.peeraddr[2]}:#{new_sock.peeraddr[1]}"
		end

		def delete_sock(sock)
			puts "Connection Break: #{sock.peeraddr[2]}:#{sock.peeraddr[1]}"
			sock.close
		rescue
			STDERR.puts "Error: #{$!}"
		ensure
			@descriptors.delete sock
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
