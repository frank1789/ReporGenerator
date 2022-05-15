#!/usr/bin/env ruby


class ProjectRevision 

	@@ACCEPTED_FORMATS = [".md", ".txt"]

	def initialize(project_directory)
		time = Time.new
		@timestamp = time.strftime("%d-%m-%Y")
		@projects_directory_ = project_directory
		@valid_projects_ = []
	end


	def scan_folders()
		folders = Dir.glob([@projects_directory_+"/**"])
		for folder in folders do
			if File.directory?(folder+"/.git")
				puts "==> found valid git project: #{folder}"
				@valid_projects_ << folder
			end
		end
	end

	def register_file_on_disk(filename = "report")
		# validate exestenison
		if @@ACCEPTED_FORMATS.include? File.extname(filename)
			# is valid nothing to do
		else 
			puts "==> #{filename} is missing extension or unsupported, then utilise the default extension"
			filename = filename + ".md"
		end
		
		filename = File.join(Dir.pwd, filename)
		# register the file on disk
		puts "==> register file: #{filename}"
		File.open(filename, "w+") { |f| 
			f.write "# Kinecar built #{@timestamp}\n"
			f.write "This file contains\n"

			f.write "\n\n"
			f.write "|  application | base version | branch | commit |\n"
			f.write "|:-------------|:------------:|:------:|:-------|\n"
			#f.write self.method


			f.write "\n\n"
			f.write "|  agl-service | base version | branch | commit |\n"
			f.write "|:-------------|:------------:|:------:|:-------|\n"
			#f.write self.method
		}
	end

	#private
	def generate_report()
		@valid_projects_.each { |e|  
			puts "==> #{e}"
			Dir.chdir(e) {
				commit  = %x[git rev-parse HEAD]
				puts "#{commit}"
				branch = %x[git rev-parse --abbrev-ref HEAD]
				puts "#{branch}"
				tag = %x[git describe --tags --abbrev=0]
				puts "found #{tag}"
				if tag.nil? || tag == 0
					puts "N.D."
				else
					puts "#{tag}"
				end

				#yield commit, branch, tag
			}
		}
	end

	def method
		fail("Block is required") unless block_given?
		if condition
			{success: true, value: yield}
		else
			{
				success: false, value: 0
			}
		end
	end
end




if __FILE__ == $0
	puts "==> Generate report current build for Kinecar"
	ARGV.each do |a|
		prr = ProjectRevision.new(a)
		prr.scan_folders
		#prr.generate_report
		prr.register_file_on_disk
	end
end
