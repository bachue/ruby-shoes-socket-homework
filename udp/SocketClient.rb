#encoding: utf-8

require 'socket'
require 'json'

class Client
	def initialize(port, server_host, server_port)
		@port = port
		@server_host = server_host
		@server_port = server_port
	end

	def login(username, password)
		@client_socket = UDPSocket.new
		@client_socket.bind nil, @port
		data, data_json = {username: username, password: password}, nil
		send data.to_json, @server_host, @server_port
		begin
			data = receive
			data_json = JSON.parse data[0]
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
		send data.to_json, @server_host, @server_port
		begin
			data = receive
			data_json = JSON.parse data[0]
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

	def close
		if @client_socket && !@client_socket.closed?
			@client_socket.close
		end
	end

	private
		def incorrect_data
			STDERR.puts 'Incorrect data'
		end

		def send(data, host, port)
			@client_socket.send data, 0, host, port
		end

		def receive
			request, address = @client_socket.recvfrom 4096
			return request, address[3], address[1], address[2]
		end
end
