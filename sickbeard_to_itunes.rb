require 'yaml'

config = YAML.load_file("config.yml")
sickbeard_download_location = config["sickbeard_download_location"]
itunes_path = config["itunes_path"]
organized_itunes = config["organized_itunes"]
path_to_handbrake = config["path_to_handbrake"]
temporary_output_path = config["temporary_output_path"]
video_quality_video_quality_preset = config["video_quality_video_quality_preset"]
handbrake_options = config["handbrake_options"]
nice_command = config["nice_command"]

def get_filename(path)
    path.split("/").last.gsub(/\.(mkv|avi|wmv)$/,"").chomp
end

def create_show_details(filename)
    filename.split(" - ")
end

def get_show_name(info)
    info.first.gsub(/\W/, " ")
end

def get_title(info)
  info.last
end

def get_season_number(info)
    if info[1] =~ /\./
       info[1].split(".").first
    elsif info[1] =~ /x/i
        info[1].downcase.split("x").first
    elsif info[1] =~ /s(\d+?)e(\d+?)/i
	$1
    end
end

def get_episode_number(info)
    if info[1] =~ /\./
      parts = info[1].split(".")
      "#{parts[1]}#{parts[2]}"
    elsif info[1] =~ /x/i
      info[1].downcase.split("x").last
    elsif info[1] =~ /s(\d+?)e(\d+?)/i
      $2
    end
end

def get_itunes_title(info)
    "#{get_season_number(info)}x#{get_episode_number(info)} #{get_title(info)}"
end

while 1 == 1

  file_list = Array.new

  `find #{sickbeard_download_location} -iname *\.mkv -o -iname *\.avi -o -iname *\.wmv`.each do |f|
    filename = get_filename(f)
    info = create_show_details(filename)
    #  This checks for new style names and old style names
    i = `find #{itunes_path} -iname "*#{filename.gsub(/\W/,"*")}*"`.chomp.size + `find #{itunes_path} -iname "*#{get_title(info)}*"`.chomp.size
    if i == 0
       file_list.push(f.chomp)
    end
  end

  file_list.each do |inPath|
      filename = get_filename(inPath)
      temporary_output_path_with_name = temporary_output_path + filename.gsub(/\W/,"_") + ".m4v"
      inPath.chomp!
      system "#{nice_command} #{path_to_handbrake}HandBrakeCLI -i \"#{inPath}\" -o \"#{temporary_output_path_with_name}\" --preset=\"#{video_quality_preset}\" #{handbrake_options}"
      temporary_output_path_with_name.gsub!(/\'/,"\\'")
      track_id = `/usr/bin/osascript -e 'tell application \"iTunes\" to add POSIX file \"#{temporary_output_path_with_name}\"'`.chomp.split(" ")[3]

      begin
	info = create_show_details(filename)
      rescue Exception => e
	puts "\n\n\n!!! Was not able to process #{filename} !!!\n\n"
	puts e.message
      end

      if info
      	# Set the episode's title
      	system "/usr/bin/osascript -e 'tell application \"iTunes\" to set name of track id #{track_id} to \"#{get_title(info)}\"'"

      	# Change the Media Kind to TV Show
      	system "/usr/bin/osascript -e 'tell application \"iTunes\" to set video kind of track id #{track_id} to tv show'"

      	# Set the season number
      	system "/usr/bin/osascript -e 'tell application \"iTunes\" to set season number of track id #{track_id} to #{get_season_number(info)}'"

      	# Set the episode number
      	system "/usr/bin/osascript -e 'tell application \"iTunes\" to set episode number of track id #{track_id} to #{get_episode_number(info)}'"

      	# Set the name of the show
      	system "/usr/bin/osascript -e 'tell application \"iTunes\" to set show of track id #{track_id} to \"#{get_show_name(info)}\"'"

      	sleep 10

      	# If the initial file addition was successful, itunes copied everything and we can delete our temporary file
      	if organized_itunes and track_id.to_i > 0
	File.delete(temporary_output_path_with_name)
      end
    end
  end

  end_time = Time.new.strftime("%m/%d %H:%M")
  if file_list.size == 0
     puts "\n\n*** [#{end_time}] No jobs to process, sleeping for an hour\n\n"
     sleep 3600
  else
     puts "\n\n*** [#{end_time}] Done with work, sleeping a half hour\n\n"
     sleep 1800
  end
end


