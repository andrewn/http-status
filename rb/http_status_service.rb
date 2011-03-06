require 'rubygems'
require 'sinatra/base'
require 'sinatra/respond_to'
require 'erb'

module HttpStatus
	class HttpStatusService < Sinatra::Base

		register Sinatra::RespondTo

		get '/' do 
			"UP"
		end

		get '/:status' do |status_code|
			
			status_code.gsub!( /xx/, '' )

			# validate status code before doing a find

			@status = HttpStatusModel.find( status_code )

			respond_to do |wants|
				wants.html 	{ erb :status, :layout => :app }
				wants.json	{ JSON.generate(@status) }
			end
		end
	end

	class HttpStatusModel
		require 'json'

		@@file_path 	= File.dirname(__FILE__) + '/../data/http_status_codes.json'
		@@statuses 		= nil

		def self.find(code)
			unless @@statuses
				self.load_statuses
			end

			code_class = self.code_class( code )

			if code.length == 3
				code_class_list 	= @@statuses[code_class]["status"]
				status_code_info	= code_class_list[code.to_s]
				status_code_info["parent"] = @@statuses[code_class]
				status_code_info
			elsif code.length == 1
				code_info = @@statuses[code_class]
			end
		end

		def self.code_class( code )
			code.to_s.slice(0,1)
		end

		def self.load_statuses
			raw_file_contents = File.read(@@file_path)
			@@statuses = JSON.parse( raw_file_contents )
		end
	end
end