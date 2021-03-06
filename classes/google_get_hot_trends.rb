
#!/usr/local/bin/ruby
class GoogleTrendsWWW
	##most of google trends online content isnt put in the atom feed; so we will make a browser instance to rendder
	#the javascript that actually creates the html that is displayed on the page
	def initialize
		require 'watir-webdriver'
		require 'headless'
		require 'nokogiri'
		require 'rubygems'
		#start up headless, the headless browser!
		@headless = Headless.new
		@headless.start
	end

	
	def get_browswer(url)
		#create the browser instance
		@url = url
		#actually start the browser now!
		@b = Watir::Browser.start @url
		@b
	end

		#
	def destroy_browser(browser)
		#destroy the browser instance when you finish
		@b = browser
		@b.close
		@headless.destroy
	end

		
	def grab_html(browser)
		#create a instance of nokogiri, an html parsing tool; this will parse the html that is rendered. 
		@b = browser
		@whole_doc = Nokogiri::HTML(@b.html)
		@whole_doc
	end

	def grab_one_day(doc)
		##google posts a bunch of trends for multiple days on the page; just grab today's date; we will be collecting the 
		##other days on the days that they are published.
		@doc =  doc
		require 'date'
		@date = DateTime.now
		@dateyear = @date.year.to_s 
		@datemonth  = @date.month.to_s
		@dateday = @date.day.to_s
		if @datemonth.size == 1 
			@datemonth = "0" + @datemonth
		end
		if @dateday.size == 1 
			@dateday = "0" + @dateday
		end
		@todays_date = @dateyear + @datemonth + @dateday
		##if working late, need to put in the date here 
		#@todays_date = "201410317"
		@div_today = "div.hottrends-trends-list-date-container#" + @todays_date
		@single_day =  @doc.css(@div_today)
		return[@todays_date, @single_day]

	end

	def get_last_updated(whole_doc)
		##google updates their trending data at weird intervals
		##when this script is set to run 1x a hour, so if something was updated 3 hours ago, 
		##then we don't need to grab the trend info because we already have it. 
		@doc =  whole_doc
		@last_update =  @doc.css("span.summary-message-text#summaryMessageText")
		@last_update.each do |trend|
			trend = trend.to_s
			#grab the time that google updated the trends
			@matches = trend.match /Updated about ([\w ]*)ago/ 
			if @matches
				@last_g_update =  @matches[1]
				@updatetime = @last_g_update.split(" ")
				##if its been updated less than hr or an hour ago, grab it; otherwise, ignore
				if @updatetime[0].chomp != "1" and @updatetime[1].chomp == 'minutes'
					return true
				elsif @updatetime[0].chomp == "1" and @updatetime[1].chomp == 'hour'
					return true
				else 
					return false
				end
			end
		end
	end

	
	def grab_trend_date(doc)
		@doc = doc
		#grab the trending trend date from the header
		@trend_days =  @doc.css("span.hottrends-trends-list-date-header-text").to_a() 
		#convert node to string
		@trend_day =  @trend_days[0].to_s
		@match1 = @trend_day.match />(\w*,? ?\w* ?\w*,? ?\w*)</
		@final_trend_day = @match1[1]
		@final_trend_day
	end

	def grab_trend_search_number(doc)
		##grab how many searches each trend has (aka how many users on google are search for the trend)
		@doc = doc
		@search_numbers = Array.new
		@nodes = @doc.search("//span[@class='hottrends-single-trend-info-line-number']")
		@nodes.each do |node|
   			@trend =  node.to_s
   			@trend_search_numb = @trend.match /\w*,?\w* ?\+/
			if @trend_search_numb
				@trend_search_numb =  @trend_search_numb.to_s
				@trend_search_numb =  @trend_search_numb.chop
				@trend_search_numb =  @trend_search_numb.gsub(/,/, '')
				##clean up the string
				@search_numbers << @trend_search_numb.chomp.strip
			end
		end
		return @search_numbers
	end

	def grab_trend_rank(doc)
		##grab the trend's rank on google
		@doc = doc
		#@trend_rank_html = @doc.css("span.")
		@trend_ranks = Array.new
		@nodes = @doc.search("//span[@class='hottrends-single-trend-index']")
		@nodes.each do |node|
   			@trend =  node.to_s
			@rank =  @trend.match /\d+/
			if @rank
				@rank = @rank.to_s
				##clean up the string
				@trend_ranks << @rank.chomp.strip
			end
		end
		@trend_ranks
	end

	def grab_trend_title(doc)
		##grab the actual trend value from the list
		@doc = doc
		@trend_title = Array.new
		@nodes = @doc.search("//span[@class='hottrends-single-trend-title']")
		@nodes.each do |node|
   			@trend =  node.to_s
			@matches =  @trend.match />([\w ]*)</
			if @matches
				@trend_title << @matches[1].chomp.strip
			end
		end
		@trend_title
	end
		
	def get_news_source(doc)
		##grab a link/reference/news source for the trend
		@doc = doc
		#@trend_news_html = @doc.css("div.hottrends-single-trend-news-article-container")
		@trend_news_source = Array.new
		@nodes = @doc.search("//div[@class='hottrends-single-trend-news-article-container']")
		@nodes.each do |node|
   			@trend =  node.to_s
			@matches = @trend.match /href="http:\/\/(www.[.\/a-zA-Z0-9\-]*)"/
			if @matches
				##clean up the string
				@trend_news_source << @matches[1].chomp.strip
			end
		end
		@trend_news_source
	end

	def get_trend_image(doc)
		##grab a link for the image of the trend
		@doc = doc
		#@trend_image_html = @doc.css("div.hottrends-single-trend-image-container")
		@trend_image_source = Array.new
		@nodes = @doc.search("//div[@class='hottrends-single-trend-image-and-text-container']")
		@nodes.each do |node|
   			@trend =  node.to_s
			@matches = @trend.match /img src="http:\/\/([.\/a-zA-Z0-9\-?=:_]*)/
			if @matches
				##clean up the string
				@trend_image_source << @matches[1].chomp.strip
			end
		end
		@trend_image_source
	end

    ##using headless/watir, automate the the headless browser to go to trend page for each country
    def get_country_specific_trendz(browser, instance)
    	@instance =  instance
    	sleep(10)
    	@b = browser
    	@country = ''
    	begin
    		#skip over item 2 in the list, its a place holder/empty
    		if instance != 2
    			@f = @b.span(:class => "popup-picker-anchor-caption")
				@country =  @f.text
				@c = @b.span(:class => "popup-picker-anchor-arrow")
				@c.click
				@d = @b.div(:class => 'goog-menu-nocheckbox picker-menu goog-menu')
				@e = @d.div(:id => ":" + @instance.to_s)
				@e.click
			end
		rescue Exception=>e
			puts e
			puts "something weird happened"
		end
		return [@country, @b]
	end

	def countrymapping(country, my_country_dict )
		@country = country
		@my_country_dict = my_country_dict
		@woeid =  @my_country_dict[@country]
	 	return @woeid
	end


	def zip_arrays_together(todays_date, country, trend_titles,trend_search_count, trend_rankings, trend_news_sources, trend_image_sources, source_data_id, my_country_dict)
	# Zipping multiple arrays together to make a big array of stuff
		@todays_date = todays_date
		@source_data_id =  source_data_id
		@country =  country
		@woeid = countrymapping(country, my_country_dict)
		@trend_titles = trend_titles
		@trend_search_count = trend_search_count
		@trend_rankings = trend_rankings
		@trend_news_sources = trend_news_sources
		@trend_image_sources = trend_image_sources

		#make an array to store all the trend info for each country
		@google_trend_list =  Array.new
		@google_trend_list_string =  Array.new
		trend_titles.zip( trend_search_count, trend_rankings, trend_news_sources, trend_image_sources ).each do |title,searchct, trrank, nwsrc, imgsrc |
  			@trend_row = Array.new
  			@trend_row << @woeid.to_s
  			@trend_row << @todays_date.chomp.strip()
  			@trend_row << source_data_id.to_s
  			@trend_row << title
  			@trend_row << searchct.chop
  			@trend_row << trrank.to_s
  			@trend_row << nwsrc 
  			@trend_row << imgsrc
  			@trend_row_string = @trend_row.join("|")
  			@google_trend_list_string << @trend_row_string
  			@google_trend_list << @trend_row
  		end
  		return[ @google_trend_list, @google_trend_list_string ]
  	end

  	def write_trend_rows_to_file (filename, google_trend_list_string)
  		@filename = filename
  		@google_trend_rows = google_trend_list_string
  		begin
  			# Create a new file and write to it  
			@myfile = File.open(@filename, 'a')
			@google_trend_rows_string.each do |trend| 
				trend.each do |t|
					@myfile.puts(t)
				end
			end
  		end
	end

	def mysanitize(string)
		@string = string
		##function to santitze strings to prevent sql injections
   		@safe_string = @string.gsub(/'/, '')
   		return @safe_string
 	end

	def insert_woeids_place_all_info_to_db(google_trend_final_list, country)
		#insert google hot data into the data; also have to clean it up a little
		@woeids = google_trend_final_list
		@insertst_orig =  'insert into tubes_trends.google_hottrends ( woeid , the_date, sdoid , trending_item, 
			trend_search_count, google_trend_ranking, trend_url, trend_image_url) VALUES '
		begin
			require_relative './MyCoolClasses.rb'
			@db = MyCoolClass.new
			#connect to sql db
			@mydb =  @db.connect_to_sqldb
			@woeids.each do |w|
				#transform certain woeids to sql strings, so you won't have insert problems
				##strings in array that need to be transformed are: [3,4, 13, 15, 16, 17, 18, 19, 20]
				@insertst = @insertst_orig + " ( "
				@mystringnumbs = [3, 6, 7]
				@mystringnumbs.each do |i| 
					@ststf = w[i] 
					if ! @ststf.nil?
						@ststf = mysanitize(@ststf)
						w[i] = "'" + @ststf + "'"
					end
				end
				w.each do |w2|
					###make sure to escape all the weird chars; Don't want a sql injection atttack on the db
					if w2.nil?
						w2 = " '',"
						@insertst = @insertst + w2 
					else
						@insertst = @insertst + w2 + ","
					end
				end
				@insertst = @insertst.chop + "); "
			@mydb.query(@insertst)
			end
		rescue Exception=>e 
			puts @insertst
			puts "Something went wrong! Trying to insert this country: " + country + "but it didn't work"
			puts e
		end
	end

	#get the woeid's for the hottrends countries; returns a dictionary of woeids
	def get_hottrend_woeids (countries_to_grab)
		@countries_to_grab = countries_to_grab
		@mysql_qr =  'select woeid, name from country where '
		@countries_to_grab.each do |g|
			@mysql_qr = @mysql_qr + "name = \'" + g + "\' or "
		end
		@mysql_qr = @mysql_qr[0..-5] + ";"
		require_relative './MyCoolClasses.rb'
		#connect to sql db
		@db = MyCoolClass.new
		##make a dictionary to store the results
		@my_country_dict = Hash.new
		#connect to sql db
		begin
		@mydb =  @db.connect_to_sqldb
		@rs =  @mydb.query(@mysql_qr)
		@rs.each_hash do |row|
   			 @my_country_dict[row['name']] = row['woeid']
		end
		rescue Exception=>e 
			puts "Something went wrong! Could not connect to DB"
			puts e
		end
		@my_country_dict
	end
end


######MAIN################

countries_to_grab = ['United States', 'Argentina', 'Austria', 'Australia', 'Belgium', 'Brazil', 'Canada', 'Colombia', 'Chile', 'Czech Republic', 'Denmark', 'France', 'Egypt', 'Finland', 'Germany','Greece','Hong Kong', 'Hungary', 'India', 'Indonesia', 'Israel', 'Italy', 'Japan', 'Kenya', 'Malaysia','Mexico', 'Netherlands', 'Nigeria', 'Norway', 'Philippines', 'Poland', 'Portugal', 'Romania', 'Russia', 'Saudi Arabia', 'Singapore', 'South Africa', 'South Korea', 'Sweden', 'Spain', 'Sweden', 'Switzerland', 'Taiwan', 'Thailand', 'Turkey', 'Ukraine', 'United Kingdom', 'Vietnam' ]
countries_to_grab = countries_to_grab.sort { |a, b| a <=> b }

##output for logging purposes--> see what trend countries are being collected ###
puts "starting to grab the hot trends!!" 
puts Time.now

##url to start out at:
url = 'http://www.google.com/trends/hottrends'
gt = GoogleTrendsWWW.new

my_country_dict = gt.get_hottrend_woeids(countries_to_grab)

#create the headless browser browser
browser = gt.get_browswer(url)

##name of file to write the trend data too; will need to write the file 
google_trends_file = "mydata/google_trends_data.txt"

#heres a list of all the countries!!! in this menu div; dynamically get the countries from the drop-down menu
##so that the script will work even if google changes the web links/addrs to the country trend data. 
ids_letters =  ("a".."z").to_a
ids_digits = (1..12).to_a
ids = ids_digits + ids_letters
#set googles source data id = 2; this number identifies google as the source of data in the db. 
source_data_id =  2

##iterate through list of countries 
ids.each do |instance|
	if instance == 2 
		next
	else
		#get the browser instance for each country
		country, country_browser = gt.get_country_specific_trendz(browser, instance)
		##grab the html from the browser. 
		whole_doc = gt.grab_html(country_browser)
		#check to see if the html was updated in the last hour
		updated_in_last_hour = gt.get_last_updated(whole_doc)
		#file name to 
		#if updated_in_last_hour
		#get the date and just the trend for today
		todays_date, doc = gt.grab_one_day(whole_doc)
		#get the search count 
		trend_search_count = gt.grab_trend_search_number(doc)
		#get the trend ranking
		trend_rankings = gt.grab_trend_rank(doc)
		#get the actual trend names
		trend_titles = gt.grab_trend_title(doc)
		#get the new source for the trend
		trend_news_sources = gt.get_news_source(doc)
		#get the image sources for the trend
		trend_image_sources = gt.get_trend_image(doc)
		#zipp the arrays together
		google_trend_list, google_trend_list_string =  gt.zip_arrays_together(todays_date, country, trend_titles,trend_search_count, trend_rankings, trend_news_sources, trend_image_sources, source_data_id, my_country_dict)
		#write trend data to a file
		#gt.write_trend_rows_to_file( google_trends_file , google_trend_list_string)
		#write trend data to db
		#gt.write_trend_rows_to_db 
		gt.insert_woeids_place_all_info_to_db(google_trend_list, country)
		puts "inserted records for " + country
	end
end

##finally destroy the browser- need to do this or will get problems
destroy = gt.destroy_browser(browser)
