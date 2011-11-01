# Path to your SickBeard library
sb_lib = "/Volumes/500GB/Sick\\ Beard"

# Path to your iTunes library
it_lib = "/Volumes/2TB/iTunes"

# iTunes copies imported files
organized_itunes = true

# Where you have HandBrakeCLI installed
pathToHB = "/Applications/"

# Temporary path your m4v files should end up before being imported to iTunes
outPath = "/Users/zach/Movies/"

# Target quality for HandBrake
preset = "AppleTV 2"

# Other options for HandBrake
options = ""

# Unix priority 19 will give up priority so your computer isn't _as_ slow
nice = "/usr/bin/nice -n 19"

# The code, no need to edit any of this unless you know what you're doing!
def get_filename(path)
    path.split("/").last.split(".").first.chomp
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
    info[1].split("x").first
end

def get_episode_number(info)
    info[1].split("x").last
end

while 1 == 1

  file_list = Array.new

  `find #{sb_lib} -iname *\.mkv -o -iname *\.avi -o -iname *\.wmv`.each do |f|
    filename = get_filename(f)
    info = create_show_details(filename)
    #  This checks for new style names and old style names
    i = `find #{it_lib} -iname "*#{filename.gsub(/\W/,"*")}*"`.chomp.size + `find #{it_lib} -iname "*#{get_title(info)}*"`.chomp.size
    if i == 0
       file_list.push(f.chomp)
    end
  end

  file_list.each do |inPath|
      filename = get_filename(inPath)
      outPathWName = outPath + filename.gsub(/\W/,"_") + ".m4v"
      inPath.chomp!
      system "#{nice} #{pathToHB}HandBrakeCLI -i \"#{inPath}\" -o \"#{outPathWName}\" --preset=\"#{preset}\" #{options}"
      outPathWName.gsub!(/\'/,"\\'")
      track_id = `/usr/bin/osascript -e 'tell application \"iTunes\" to add POSIX file \"#{outPathWName}\"'`.chomp.split(" ")[3]
      info = create_show_details(filename)
      
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
        File.delete(outPathWName)
      end
  end

  if file_list.size == 0
     puts "\n\n*** No jobs to process, sleeping for an hour\n\n"
     sleep 3600
  else
     puts "\n\n*** Done with work, sleeping a half hour\n\n"
     sleep 1800
  end
end


