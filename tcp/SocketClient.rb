#encoding: utf-8

require 'socket'
require 'json'

class Client
	def initialize(host, port)
		puts 'Connecting...'
		@client_socket = TCPSocket.open host, port
		local, peer = @client_socket.addr, @client_socket.peeraddr
		puts "Connected to #{peer[2]}:#{peer[1]}"
		puts "using local port #{local[1]}"
	end

	def login(username, password)
		data, data_json = {username: username, password: password}, nil
		@client_socket.puts data.to_json
		begin
			data = @client_socket.gets
			data_json = JSON.parse data
		rescue 
			STDERR.puts "Error: #{$!}"
			return nil
		end

		p data_json

		if data_json['success'] == true
			if @session_id = data_json['session_id']
				true
			else
				incorrect_data
			end
		elsif data_json['success'] == false
			if message = data_json['message']
				STDERR.puts "Msg: #{message}"
				return false, message
			else
				incorrect_data
			end
		else
			incorrect_data
		end
	end

	def transfer(sent_data)
		data, data_json = {data: sent_data, session_id: @session_id}, nil
		@client_socket.puts data.to_json
		begin
			data = @client_socket.gets
			data_json = JSON.parse data
		rescue 
			STDERR.puts "Error: #{$!}"
		end

		if data_json['success'] == true
			if message = data_json['message']
				return true, message
			else
				incorrect_data
			end
		elsif data_json['success'] == false
			if message = data_json['message']
				STDERR.puts "Msg: #{message}"
				return false, message
			else
				incorrect_data
			end
		else
			incorrect_data
		end

	end

	def quit
		transfer 'quit'
	end

	private
		def incorrect_data
			STDERR.puts 'Incorrect data'
		end
end
