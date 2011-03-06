require 'rubygems'
require 'nokogiri'

INPUT_PATH  = 'data/http_status_codes.html'
OUTPUT_PATH = 'data/http_status_codes.json'

# Get a Nokogiri::HTML:Document for the page we’re interested in...
doc = Nokogiri::HTML File.read INPUT_PATH

body = doc.css('body')

@group_matcher 	= /sec10.([^.]\d*)$/
@status_matcher = /sec10.([^.]\d*).([^.]\d*)$/

@group_content_splitter  = /^10.[^.]\d* (.*) (\dxx)$/
@status_content_splitter = /^10.[^.]\d*.[^.]\d* (\d*) (.*)$/

@in_group  = false
@in_status = false

def get_id( node )
	node.css('*[id]').attr('id').value
end

def get_id_type( node )
	id = get_id(node)
	if id and @group_matcher.match( id )
		return :group
	elsif id and @status_matcher.match( id )
		return :status
	else
		return nil
	end
end

def group_info( str )
	matches = @group_content_splitter.match str
	return {
		:title => $1,
		:code  => $2
	}
end

def status_info( str )
	matches = @status_content_splitter.match str
	return {
		:code   => $1,
		:title  => $2
	}
end

def sanitize( str )
	str.strip.gsub( /\n/, '' )
end

groups = {}
current_group = nil # { :desc => [], :status => [] }
current_status = nil # { :code => '', :title => '', :desc => [] }

body.children.each do |node|
	if node.name == 'h3'
		node_type = get_id_type( node )
		
		if node_type == :group

			current_status = nil

			current_group = { 
				:title  => group_info(node.inner_text)[:title], 
				:code   => group_info(node.inner_text)[:code],
				:desc   => [], 
				:status => {} 
			}
			@in_group  = true
			@in_status = false

			# Add the new group to the object now
			# We add statuses to the object reference
			group_code = current_group[:code].slice(0,1)
			groups[group_code] = current_group 

		elsif node_type == :status
			# entered new status
			@in_status = true
			
			current_status = { :code => '', :title => '', :desc => [] }
			current_status[:title] = status_info(node.inner_text)[:title]
			current_status[:code]  = status_info(node.inner_text)[:code].to_i

			# Add the status to the correct group
			current_group[:status][current_status[:code]] = current_status
		end
	else
		if !@in_group and !@in_status
			# in doc
			#p node
		elsif @in_group and !@in_status
			# group desc
			current_group[:desc] << sanitize(node.inner_text)
		elsif @in_group and @in_status
			# a status
			current_status[:desc] << sanitize(node.inner_text)
		end
	end
end

def collapse( array ) 
	str = ""
	array.each do | block | 
		str << block
	end
	str
end

# Post-process text blocks
groups.each do | code, group |
	if group[:desc]
		group[:desc] = collapse( group[:desc].join(" ") )
	end

	if group[:status]
		group[:status].each do | code, status |
			if status[:desc]
				status[:desc] = collapse( status[:desc].join(" ") )
			end
		end
	end
end

# Output as JSON
require 'json'
json = JSON.pretty_generate( groups )

File.open( OUTPUT_PATH, 'w') {|f| f.write(json) }
