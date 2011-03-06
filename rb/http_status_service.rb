require 'rubygems'
require 'sinatra/base'
require 'vendor/sinatra-respond_to-0.6.0/lib/sinatra/respond_to'
require 'erb'

module HttpStatus
	class HttpStatusService < Sinatra::Base

		register Sinatra::RespondTo

		get '/' do 
			"UP"
		end

		get '/:status' do |status_code|
			
			status_code.gsub!( /xx/, '' )

			# TODO: validate status code before doing a find
			#

			@status 		= HttpStatusModel.find( status_code )
			@status["url"] 	= url_for_status(status_code)
			
			if status_code.length == 3
				parent_status = HttpStatusModel.find( status_code.to_s.slice(0,1) )
				@status["parent"] = {
					"code"	=> parent_status["code"],
					"title" => parent_status["title"],
					"url"	=> url_for_status( parent_status["code"] )
				}
			end

			if status_code.length == 1
				@status["status"] = order_status( @status["status"] )
			end

			respond_to do |wants|
				wants.html 	{ erb :status, :layout => :app }
				wants.json	{ JSON.generate(@status) }
			end
		end

		def order_status( hash )
			sorted_array = hash.sort
			sorted_array.map { |item| item[1] }
		end

		def url_for_status( code )
			"/" + code
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
				status_code_info
			elsif code.length == 1
				status_code_info = @@statuses[code_class]
			end

			@@statuses = nil

			status_code_info
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