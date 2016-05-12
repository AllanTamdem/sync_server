module PathHelper

	def path_prettify path
		if path.nil?
			path = ""
		end

		if path.length != 0 and !path.end_with? "/"
			path = path + "/"
		end

		if(path.start_with? "/")
			path = path[1..-1]
		end

		while path.include? "//"
			path.gsub!("//", "/")
		end

		path
	end

	def path_concat(path1, path2)

		path_prettify(path1) + path_prettify(path2)

	end

end