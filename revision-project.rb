#!/usr/bin/env ruby

KNOW_FOLDER = ["app", "script", "package","autobuild","conf.d","bazel-bin", "bazel-out", "bazel-testlogs", "tests", "bazel-speech", "binding", "app_test", "thirdparty", "build", "asset", "readme-asset", "assets"]


def filter_know_subfolder(counter, projects)
	for subproject in projects do
		if File.directory?(subproject) && !KNOW_FOLDER.include?(subproject.split('/').last)
			result = subproject.split('/').last
			puts "kkk #{result}"
			counter += 1
			yield(counter, result)
		end
	end
end



class Project
	attr_accessor :name_, :branch_, :commit_, :tag_



	def initialize(name, branch, commit, tag = "N.A.")
		@size = 0
		@name_ = has_subproject(name)
		@branch_ = valid_branch(branch)
		@commit_ = commit
		@tag_ = tag
	end


	def get_project
		if @size == 0 
			return nil
		end
		if @size == 1
			return {name: 		@name_,	branch:  	@branch_, commit: 	@commit_,	tag: 		@tag_}
		end
		if @size > 1
		 	return []
		end
	end

	def size
		@size
	end

	def to_s
	end


	private
	def valid_branch(branch)
		branch = branch.strip
		case branch
		when "main"
			return branch
		when "master"
			return branch
		when "develop"
		 	return branch
		when /feature\/.*/
			return branch
		when /hotfix\/.*/
			return branch
		when /release\/.*/
			return branch
		when /experiment.*/
			return branch
		else
			raise "Not found a valid branch name"
		end
	end

	def has_subproject(name)
		out = nil
		subfolders = Dir.glob([name + "/**"])
		filter_know_subfolder(@size, subfolders){
			|i, res| puts "kuri #{i}, #{res}"
			@size = i
			if i == 1
				out = name.split('/').last
			elsif i > 1
				out << res
			else
				out = res
			end

		}
		out
	end
end


class ProjectRevision 

	@@ACCEPTED_FORMATS = [".md", ".txt"]

	def initialize(project_directory)
		time = Time.new
		@timestamp = time.strftime("%d-%m-%Y")
		@projects_directory_ = project_directory
		@repository_projects_ = []
		@valid_projects_ = []
	end


	def scan_folders()
		folders = Dir.glob([@projects_directory_+"/**"])
		for folder in folders do
			if File.directory?(folder+"/.git")
				puts "==> found valid git project: #{folder}"
				@repository_projects_ << folder
			end
		end
	end

	def register_file_on_disk(filename = "report")
		# validate extension
		if @@ACCEPTED_FORMATS.include? File.extname(filename)
			# filename is valid nothing to do
		else 
			puts "==> #{filename} is missing extension or unsupported, then utilise the default extension"
			filename = filename + ".md"
		end
		
		# register the file on disk
		filename = File.join(Dir.pwd, filename)
		puts "==> register file: #{filename}"
		File.open(filename, "w+") { |f| 
			f.write "# Kinecar built #{@timestamp}\n"
			f.write "This file contains\n"

			f.write "\n\n"
			f.write "|  application | base version | branch | commit |\n"
			f.write "|:-------------|:------------:|:------:|:-------|\n"
			@valid_projects_.each { |line| 
				if !line.nil?
					f.write "\| %s \| %s \| %s \| ``%s`` |\n" % [line[:name], line[:tag], line[:branch], line[:commit]]
				end
			}
			


			f.write "\n\n"
			f.write "|  agl-service | base version | branch | commit |\n"
			f.write "|:-------------|:------------:|:------:|:-------|\n"
			

			#f.write 
		}
	end

	#private
	def generate_report()
		@repository_projects_.each { |e|  
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

				project = Project.new(e.strip, branch.strip, commit.strip, tag.strip)
				p project
				if !project.nil?
					if project.get_project.kind_of?(Array)
						project.get_project.each {|element| @valid_projects_ << element }
					else
						puts "zzzz #{project.get_project}"
						@valid_projects_ << project.get_project
					end
				end
				#yield commit, branch, tag

				puts @valid_projects_.length()
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
		prr.generate_report
		prr.register_file_on_disk
	end
end
