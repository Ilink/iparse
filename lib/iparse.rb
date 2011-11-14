module Iparse
  require 'nokogiri'
  # =Iparse :: Ruby iTunes XML Parser
  # This class takes a properly-formed XML iTunes library file and makes a hash
  #   *EG: "Artist" => "Nick Cave"
  # While this should be a simple task with any parser, Apple decided to make their XML strangely formed.
  #   *For instance, a song title would be referenced as <key>Song Title</key><string>Tupelo</string>
  # Therefore, the XML must be parsed in a very specialized fashion.
  #
  # ==Depdendencies:
  # Nokogiri (and all of it's dependencies)
  #   *Only tested with Nokogiri 1.5.0 and Ruby 1.9.2
  #   *Nokogiri is available from http://nokogiri.org
  #
  # ==Usage:
  # Simply call the function with the appropriate filepath
  #   *EG: itunes_parser('app/assets/itunes.xml')
  #	Returns a hash of data representing your library. Keys be entries in the library, eg: ['album'] => 'Rain Dogs'
  #
  # ==Speed:
  # iTunes libary XML files can be quite large, making speed an important consideration for this parser. Nokogiri's excellent XML Reader class is used for simplicity and speed. The parser doesnt read in the entire XML structure, rather it uses a SAX-like approach. Benchmark stats coming soon, though in my experience, working with 100s of thousands of lines of XML is no problem. Other benchmarks illustrate the speed of Nokogiri quite eloquently.

  def self.parse (file_location)
    f = File.open(file_location)
    @xml_data = {}
    @xml_collector = []
    @reader = Nokogiri::XML::Reader(f)
    song_iterator = -1
    num_dict = 0  # the even <dict> tags represent closing tags, assuming document is well-formed
    @reader.each do |node|
      if node.value !~ /\n/ #remove newlines
        if node.name == 'dict' && node.depth == 3 #iTunes puts in a bunch of extraneous <dict> nodes that we must ignore. Relevent information really begins 3 levels deep
          num_dict += 1
          if num_dict % 2 > 0 # the even <dict> tags represent closing tags, assuming document is well-formed
            song_iterator = song_iterator + 1
            @xml_data[song_iterator] = {}
          else #the reader has encountered a closing </dict> tag so we place the values of the song into the main hash
            (0..@xml_collector.length).step(2) do |i|
              if !@xml_collector[i].nil?
                @xml_data[song_iterator][@xml_collector[i]] = @xml_collector[i + 1]
              end
            end
            @xml_collector = [] #get rid of previous values since we already added those to the hash
          end
        end
        if node.depth >= 5
          @xml_collector.push(node.value) # get all the name/value pairs in the
        end
      end
    end
    @xml_data # return collected data
  end

end