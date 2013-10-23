### Copyright Cloverhound, Inc.
###
### Chad Stachowicz
###
### cstachowicz@cloverhound.com

require 'win32ole'
require 'date'
require 'fileutils'
require 'yaml'
require 'logger'

@@settings = YAML.load_file("C://Cloverhound//Config Files//MediaServerSync.yaml")
@@logger = Logger.new('C:\\Cloverhound\\Media File Backups\\Logs\\logfile.log','daily')
@@logger.info{ "Started Sync Process..."}
@@starttime = Time.new.inspect

def map_my_drives
    net = WIN32OLE.new('WScript.Network')
    (1..@@settings.count).each do |i|
      drive = @@settings["server" + i.to_s]["letter"] + ":"
      iphost = @@settings["server" + i.to_s]["iphost"]
      username = @@settings["server" + i.to_s]["username"]
      password = @@settings["server" + i.to_s]["password"]
      if !File.directory?(drive)
        net.MapNetworkDrive(drive, "\\\\#{iphost}\\MediaFiles", nil,  username, password )
	@@logger.info{ "Mapped network drive #{drive} at #{iphost}"}
      end
    end
end

def transfer_file(filename, item, lastrun, current_directory="")
	(1..@@settings.count).each do |i|
		drive = @@settings["server" + i.to_s]["letter"] + ":\\"
		filen = filename.clone
		fsub = filen.sub!("C:\\Cloverhound\\Media Files", "")
		drive = @@settings["server" + i.to_s]["letter"] + ":\\"
		filen2 = drive + fsub
		if File.exist?(filen2)
			filek = lastrun.clone
			fsub2 = filek.gsub!(/[\:\-]/,"")
			newdir = "C:\\Cloverhound\\Media File Backups\\#{filek}"
			if !File.directory?(newdir)
				FileUtils.mkdir(newdir)
				@@logger.info{ "Created #{newdir}"}
			end
			if !File.exist?(newdir + "\\" + item)
				FileUtils.cp_r(filen2,newdir)
				@@logger.info{ "Backed up #{item} from #{@@settings["server" + i.to_s]["iphost"]} to #{newdir}"}
			end
		end
		FileUtils.cp_r(filename,drive + current_directory)
		@@logger.info{ "Transferred #{filename} to #{@@settings["server" + i.to_s]["iphost"]}"}
	end
end


def folder_cycle(lastrun,folder="C:\\Cloverhound\\Media Files",prevfold=0) 
	if folder == "C:\\Cloverhound\\Media Files"
		if DateTime.parse(File.mtime(folder).to_s) > DateTime.parse(lastrun)
			prevfold=1
		end
	end
	filenames = []
 	Dir.foreach(folder) do |item|
   		filenames.push(item)
 	end
 	filenames.each do |item|
  		if item != '..' && item != '.'
   			filename = folder + "\\" + item
   			ftim = File.ctime(filename)
   			mtim = File.mtime(filename)
			atim = File.atime(filename)
			filem = filename.clone
			fsum3 = filem.sub!("C:\\Cloverhound\\Media Files", "")
			puts item
			if DateTime.parse(lastrun) < DateTime.parse(ftim.to_s) || DateTime.parse(lastrun) < DateTime.parse(mtim.to_s)
				if File.directory?(filename)
			
					(1..@@settings.count).each do |i|
						drive = @@settings["server" + i.to_s]["letter"] + ":\\"
						newdir = drive + fsum3
						if !File.directory?(newdir)
							FileUtils.mkdir(newdir)
							@@logger.info{ "Created #{newdir}"}
							filen = filename.clone
							fsub = filen.sub!("C:\\Cloverhound\\Media Files\\", "")
							fsub2 = fsub.sub!("\\" + item, "\\\\\\")
						end
					end
				   folder_cycle(lastrun,filename,1)
				else
					(1..@@settings.count).each do |i|
						drive = @@settings["server" + i.to_s]["letter"] + ":\\"
						newfile = drive + fsum3
						if !File.exist?(newfile)
							filen = filename.clone
							fsub = filen.sub!("C:\\Cloverhound\\Media Files\\", "")
							fsub2 = fsub.sub!("\\" + item, "\\\\\\")
							if fsub2.nil?
								transfer_file(filename,item,lastrun)
							else
								
								transfer_file(filename,item,lastrun,fsub2)
							end
						end
					end
				end
			elsif File.directory?(filename)
				folder_cycle(lastrun,filename)
			elsif prevfold==1
				(1..@@settings.count).each do |i|
					drive = @@settings["server" + i.to_s]["letter"] + ":\\"
					newfile = drive + fsum3
					if !File.exist?(newfile)
						filen = filename.clone
						fsub = filen.sub!("C:\\Cloverhound\\Media Files\\", "")
						fsub2 = fsub.sub!("\\" + item, "\\\\\\")
						if fsub2.nil?
							transfer_file(filename,item,lastrun)
						else	
							transfer_file(filename,item,lastrun,fsub2)
						end
						@@logger.info{ "Transferred #{filename} to #{@@settings["server" + i.to_s]["iphost"]}"}
					end
				end
			end
  		end
 	end
end


map_my_drives

lastrun = ""
if File.file?('last-run-time.txt')
  File.open('last-run-time.txt', 'r') do |file| 
    while (line = file.gets)
        lastrun = line
    end
  end
end
if lastrun.empty?
    lastrun = @@starttime
end
begin
 folder_cycle(lastrun)
 @@logger.info{ "Completed Sync Process..."}
rescue => err
  @@logger.fatal("Caught exception; exiting")
  @@logger.fatal(err)
end

File.open("last-run-time.txt", 'w') { |file| file.write(@@starttime) }