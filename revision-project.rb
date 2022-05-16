#!/usr/bin/env ruby

KNOW_FOLDER = ["app", "apps","script", "package", "autobuild", "conf.d", "bazel-bin", "bazel-out", "bazel-testlogs", "tests", "bazel-speech", "binding", "app_test", "thirdparty", "build", "asset", "readme-asset", "assets",  "libs", "can_samples", "docs", "test_can_h", "plugin", "plugins", "examples", "low-level-can-generator", "include"]
STRUCTURE_SERVICE = ["autobuild", "conf.d", "binding"]
STRUCTURE_APP = ["autobuild", "conf.d", "app"]

def filter_know_subfolder(counter, projects)
  for subproject in projects
    if File.directory?(subproject) && !KNOW_FOLDER.include?(subproject.split("/").last)
      result = subproject.split("/").last
      counter += 1
      yield(counter, result)
    end
  end
end

class Project
  attr_accessor :name_, :branch_, :commit_, :tag_

  @@SINGLE_FOLDER = ["meta-kinecar", "agl-image", "agl-compositor", "qtapplicationframework"]

  def initialize(name, branch, commit, tag)
    @size = 0
    @name_ = has_subproject(name)
    @branch_ = valid_branch(branch)
    @commit_ = commit
    @tag_ = !tag.nil? ? tag : "N.D"
  end

  def get_project
    result = []
    for name in @name_
      if !@branch_.nil?
        result << { name: name, branch: @branch_, commit: @commit_, tag: @tag_ }
      end
    end
    return result
  end

  def size
    @size
  end

  private

  def valid_branch(branch)
    branch = branch.strip
    case branch
    when "main"
      return branch
    when "master"
      return branch
    when /develop/
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
      return nil
    end
  end

  def has_subproject(name)
    out = []
    if @@SINGLE_FOLDER.include?(name.split("/").last)
      out << name.split("/").last
    elsif check_structure_dir(name)
      out << name.split("/").last
    else
      subfolders = Dir.glob(["*"])
      filter_know_subfolder(@size, subfolders) { |i, res| @size = i; out << res }
      out
    end
  end

  def check_structure_dir(directory)
    puts "==> check structure directory: #{directory}"
    valid = false
    subfolders = Dir.glob([File.join(directory, "*")])
    for subproject in subfolders
      if STRUCTURE_SERVICE.include?(subproject.split("/").last) || STRUCTURE_APP.include?(subproject.split("/").last)
        valid = true
      end
    end
    valid
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
    folders = Dir.glob([File.join(@projects_directory_, "*")])
    for folder in folders
      if File.directory?(folder)
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
      f.write "# Kinecar image built #{@timestamp}\n\n"
      f.write "## kinecar-platform v#{"0.1.0"}\n"

      f.write "\n"
      f.write "|  Application | base version | branch | commit |\n"
      f.write "|:-------------|:------------:|:------:|:-------|\n"
      @valid_projects_.each { |line|
        if !line.nil?
          f.write "\| %s \| %s \| %s \| ``%s`` |\n" % [line[:name], line[:tag], line[:branch], line[:commit]]
        end
      }
    }
  end

  #private
  def generate_report()
    @repository_projects_.each { |d|
      Dir.chdir(d) {
        # reset the folder extract informatio
        if !d.match(/\w+\/(homescreen)/)
          %x[git stash; git clean -fxd; git checkout develop 2> /dev/null]
        else
          %x[git stash; git clean -fxd 2> /dev/null]
        end
        commit = %x[git rev-parse HEAD 2> /dev/null]
        branch = %x[git rev-parse --abbrev-ref HEAD 2> /dev/null]
        tag = %x[git describe --tags --abbrev=0 2> /dev/null]
        puts "==> #{d} #{tag.strip} #{branch.strip} #{commit.strip}" 
        project = Project.new(d, branch.strip, commit.strip, tag.strip)
        if !project.nil?
          if project.get_project.kind_of?(Array)
            project.get_project.each { |element| @valid_projects_ << element }
          else
            @valid_projects_ << project.get_project
          end
        end
      }
    }
  end
end


# require 'json'
# tempHash = {
#     "key_a" => "val_a",
#     "key_b" => "val_b"
# }
# File.open("public/temp.json","w") do |f|
#   f.write(JSON.pretty_generate(tempHash))
# end



# class Configuration
  
#   def initialize
#     @date
#     @version
#   end


#   def register_file_on_disk
#     File.open("public/temp.json","w") do |f|
#       f.write(JSON.pretty_generate(tempHash))
#     end
#   end

# end

if __FILE__ == $0
  puts "==> Generate report current build for Kinecar"
  ARGV.each do |a|
    prr = ProjectRevision.new(a)
    prr.scan_folders
    prr.generate_report
    prr.register_file_on_disk
  end
end
