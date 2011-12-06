#encoding: utf-8

require './SocketClient.rb'

Shoes.app :title => 'Ruby Socket Experiment', :width => 300, :height => 320 do
	stack do
		para 'Username:'
		@username_edit = edit_line :left => 80, :width => 300
		para 'Password:'
		@password_edit = edit_line :left => 80, :width => 300, :secret => true
		para 'Host:'
		@host_edit = edit_line :left => 80, :text => 'localhost', :width => 300
		para 'Port:'
		@port_edit = edit_line :left => 80, :text => 8001, :width => 300
		button 'Login', :left => 110, :bottom => -50 do
			['username', 'password', 'host', 'port'].each do |name|
				if eval("@#{name}_edit").text.size < 1
					alert("#{name.capitalize} can't be blank")
					return
				end
			end


			$client = Client.new @host_edit.text, @port_edit.text
			result, message = $client.login @username_edit.text, @password_edit.text

			unless result
				alert message || 'something error'
				next
			end

			dialog :width => 400, :height => 180, :title => "#{@username_edit.text.capitalize}'s Messages" do
				stack :margin => 20 do
					flow do
						@send_button = button 'Send:', :width => 50
						@send_edit = edit_line :left => 60, :width => 300
					end

					flow do
						para 'Result:'
						@result_text = para '', :left => 80
					end

					flow do
						para 'Data:' 
						@received_text = para '', :left => 80
					end

					flow do
						@quit_button = button 'Quit', :left => 160
					end
				end

				@send_button.click do
					if @send_edit.text.size > 0
						result, message = $client.transfer @send_edit.text
						if result
							@result_text.text = 'Success'
							@received_text.text = message
						else
							@result_text.text = 'Failure'
							@received_text.text = message
						end
					end
				end

				@quit_button.click do
					$client.quit
					close
				end
			end
		end
	end
end
