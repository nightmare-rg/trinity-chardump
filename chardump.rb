#!/usr/bin/ruby

require 'fileutils'

TMPDIR = 'chardumps-tmp'
SQLFILE = ARGV[0]
GUID = ARGV[1].to_i
CHARNAME =  ARGV[2]
TABLES = %w(characters character_account_data character_achievement character_achievement_progress character_action character_glyphs character_homebind character_inventory character_pet character_queststatus character_queststatus_rewarded character_reputation character_skills character_spell item_instance)

def getTables

  tables = []
  regexp = /^-- Table structure for table `(.*)`/

  file = File.new(SQLFILE, 'r')

  while (line = file.gets)
    if md = regexp.match(line.force_encoding('iso-8859-1'))
      tables.push(md[1])
    end
  end

  file.close

  return tables

end

def splitTables

  file = File.new(SQLFILE, 'r')

  Dir::mkdir(TMPDIR) if not FileTest::directory?(TMPDIR)

  #tables = getTables
  tables = TABLES

  tables.each { |table|

    regexp = /^-- Dumping data for table `#{table}`/
    regexp_end =  /^-- Table structure for table/

    data = []

    match = 0

    while (line = file.gets)

      if md = regexp.match(line.force_encoding('iso-8859-1'))

        match = 1

      elsif md_end = regexp_end.match(line.force_encoding('iso-8859-1'))

        match = 0

      end

      data.push(line) if match == 1

    end

    file.rewind
    file.lineno

    File.open("#{TMPDIR}/#{table}", 'w') {|f| data.each { |string| f.write(string.gsub('),',"),\n")) }}

  }

  file.close

end

def extractData

  tables = TABLES

    tables.each { |table|

      case table
        when 'characters'
          if not GUID.nil? and GUID.is_a? Numeric
            regexp = /\(#{GUID},\d*,'.*',.*\)/
          elsif not CHARNAME.nil? and GUID.is_a? String
            regexp = /\(\d*,\d*,'#{CHARNAME}',.*\)/
          end
        when 'character_account_data'
          regexp = /\(#{GUID},\d*,.*\)/
        when 'character_achievement'
          regexp = /\(#{GUID},\d*,.*\)/
        when 'character_achievement_progress'
          regexp = /\(#{GUID},\d*,\d*,.*\)/
        when 'character_action'
          regexp = /\(#{GUID},\d*,.*\)/
        when 'character_glyphs'
          regexp = /\(#{GUID},\d*,.*\)/
        when 'character_homebind'
          regexp = /\(#{GUID},\d*,\d*,.*\)/
        when 'character_inventory'
          regexp = /\(#{GUID},\d*,\d*,.*\)/
        when 'character_pet'
          regexp = /\(\d*,\d*,#{GUID},.*\)/
        when 'character_queststatus'
          regexp = /\(#{GUID},\d*,\d*,.*\)/
        when 'character_queststatus_rewarded'
          regexp = /\(#{GUID},\d*,\d*\)/
        when 'character_reputation'
          regexp = /\(#{GUID},\d*,.*\)/
        when 'character_skills'
          regexp = /\(#{GUID},\d*,.*\)/
        when 'character_spell'
          regexp = /\(#{GUID},\d*,.*\)/
        when 'item_instance'
          regexp = /\(#{GUID},\d*,.*\)/
        else
          return
      end

      file = File.new("#{TMPDIR}/#{table}", 'r')

      while (line = file.gets)

        if md = regexp.match(line.force_encoding('iso-8859-1'))

          File.open("#{TMPDIR}/#{table}.extract", 'a') {|f|  f.write("#{md};\n") }

        end

      end

    }

end

def createPDump

  File.delete("guid_#{GUID}.pdump") if File.exists?("guid_#{GUID}.pdump")

  file = File.new("guid_#{GUID}.pdump", 'a')

  file.puts "IMPORTANT NOTE: THIS DUMPFILE IS MADE FOR USE WITH THE 'PDUMP' COMMAND ONLY - EITHER THROUGH INGAME CHAT OR ON CONSOLE!"
  file.puts 'IMPORTANT NOTE: DO NOT apply it directly - it will irreversibly DAMAGE and CORRUPT your database! You have been warned!'
  file.puts "\n"
  file.puts "INSERT INTO `characters` VALUES #{File.read("#{TMPDIR}/characters.extract")}"

  Dir.glob("#{TMPDIR}/*.extract").each do|f|

    if f !~ /characters.extract/

      readFile = File.new(f, 'r')

      while (line = readFile.gets)

        file.puts "INSERT INTO `#{f.gsub("#{TMPDIR}/",'').gsub('.extract','')}` VALUES #{line}"

      end

    end

  end

end

def cleanTMP

  FileUtils.rm_rf(TMPDIR) if FileTest::directory?(TMPDIR)

end

splitTables
extractData
createPDump
cleanTMP

