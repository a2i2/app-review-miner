#!/usr/bin/ruby

require 'optparse'
require 'ostruct'
require 'net/https'
require 'uri'
require 'json'
require 'nokogiri'
require 'sequel'
require "yaml"
require './utils/Options.rb'

# This script is used to fetch the list of top applications from iOS app ranking, and exports the results into CSV string.

# Load options
countries = Options.parse_countries("options/countries.csv")
feed_types = Options.parse_feed_types("options/feedTypes.csv")
genres = Options.parse_genres("options/genres.csv")

config = YAML.load_file("db_config.yaml")
DB = Sequel.connect(:adapter=>'postgres', :host=>config["host"], :database=>config["database"], :user=>config["user"], :password=>config["password"])
apps_table = DB[:apps]
reviews_table = DB[:reviews]

# Command line parameters processing
def parseOptions(args, countries, feed_types, genres)
    options = OpenStruct.new
    # Default count parameter is 100
    options.count = 100

    opts = OptionParser.new do |opts|
        opts.banner = "Usage: indexApps_iOS.rb -c countrycode -t feedid -g genreid [-n count]"

        opts.separator ""
        opts.separator "Specific options:"

        # Generate a list of countries
        country_strings = countries.map do |code, country|
            "\t" + code + ":\t" + country[:name]
        end

        # Process country code parameter
        opts.on("-c", "--country countrycode", "Country code of the store to download from", *country_strings) do |country|
            options.country = country.downcase
        end

        # Generate a list of feed types
        feed_strings = feed_types.each_with_index.map do |feed_type, idx|
            "\t" + idx.to_s + ":\t" + feed_type[:name]
        end

        # Process feed type parameter (free == 0, paid == 1)
        opts.on("-t", "--type feedid", Integer, "Type of feed to fetch", *feed_strings) do |feed_type|
            options.feed_type = feed_type
        end

        # Generate a list of genres (0 == all, books == 1 ... )
        genre_strings = genres.each_with_index.map do |genre, idx|
            "\t" + idx.to_s + ":\t" + genre[:name]
        end

        # Process genre parameter
        opts.on("-g", "--genre genreid", Integer, "Genre of applications to list", *genre_strings) do |genre|
            options.genre = genre
        end

        # Process count parameter
        opts.on("-n", "--number count", Integer, "Number of applications to list (0 <= count <= 400)") do |count|
            options.count = count
        end

        opts.separator ""
        opts.separator "Common options:"

        opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
        end
    end

    opts.parse!(args)

    if options.country.nil? || options.genre.nil? || options.feed_type.nil? ||\
       countries.detect { |code, country| code.downcase == options.country }.nil? ||\
       options.genre < 0 || options.genre >= genres.length ||\
       options.feed_type < 0 || options.feed_type >= feed_types.length ||\
       options.count <= 0 || options.count > 400
        puts opts
        exit
    else
        # Log the current action being taken ('warn' used to ensure console output)
        warn "Indexing #{options.country}_#{feed_types[options.feed_type][:short_name]}_#{genres[options.genre][:short_name].downcase}..."
        options
    end
end

# Parse command line parameters
options = parseOptions(ARGV, countries, feed_types, genres)

# Build the API URL from the options
target_url = "http://itunes.apple.com/"
target_url << options.country.downcase << "/rss/" << feed_types[options.feed_type][:value] << "/limit=" << options.count.to_s << "/"
if options.genre > 0
    target_url << "genre=" << genres[options.genre][:value] << "/"
end
target_url << "json"

# Load the list of applications from the URL
parsed_url = URI.parse(target_url)

success = false
until success
    success = true
    http = Net::HTTP.new(parsed_url.host, parsed_url.port)
    begin
        content = http.start do |w| w.get(target_url).body end
        content_struct = JSON.parse(content)
    rescue => detail
        success = false
        sleep(1)
    end
end

# Output CSV if content has been successfully fetched
unless content_struct.nil?
    app_list = content_struct["feed"]["entry"]
    if app_list.class == Hash
        app_list = [app_list]
    end

    result = []
    threads = []
    app_queue = Queue.new

    # Queue applications to be indexed
    app_list.each_with_index do |app, index|
        app_queue << { :index => index, :app => app }
    end

    # Export the data to CSV
    20.times do
        threads << Thread.new do
            until app_queue.empty?
                job = app_queue.pop(true) rescue nil

                unless job.nil?
                    index = job[:index]
                    app = job[:app]

                    app_id = app["id"]["attributes"]["im:id"]
                    app_name = app["im:name"]["label"]
                    app_url = "http://itunes.apple.com/" + options.country + "/app/id" + app_id
                    app_price = app["im:price"]["attributes"]["amount"]
                    app_currency = app["im:price"]["attributes"]["currency"]
                    app_size = ""
                    app_version = ""

                    # Download the application page to fetch the version number and the binary size
                    uri = URI(app_url)
                    success = false
                    until success
                        success = true
                        begin
                            page_content = Net::HTTP.get(uri)
                        rescue => detail
                            warn "Page download failed - retry"
                            success = false
                            sleep(1)
                        end
                    end

                    unless page_content.nil? || page_content.length == 0
                        # Load the HTML content
                        html_doc = Nokogiri::HTML(page_content)
                        lis = html_doc.xpath("//div[@id='left-stack']//li")
                        lis.each do |li|
                            li_str = li.text.strip
                            if li_str.start_with?("Size: ", "size: ")
                                app_size = li_str[6..-1]
                            end
                            if li_str.start_with?("Version: ", "version: ")
                                app_version = li_str[9..-1]
                            end
                        end
                    end

                    csv_row = CSV::Row.new([], [app_name, app_id, options.country, app_url, app_price, app_currency, app_size, app_version, index + 1])

                    # Format the csv string with || as delimiter
                    pipe_delimited_csv_row = CSV.generate(:col_sep => "||") do |csv|
                        csv << csv_row
                    end

                    result << { :index => index + 1, :result => pipe_delimited_csv_row.to_s }

                    # Insert app into the database (if not already there)
                    begin
                        if apps_table.filter(:app_id => app_id, :app_version => app_version).count == 0
                            apps_table.insert(:app_id => app_id,
                                              :app_name => app_name,
                                              :app_url => app_url,
                                              :app_price => app_price,
                                              :app_currency => app_currency,
                                              :app_size => app_size,
                                              :app_version => app_version,
                                              :app_rank => index + 1,
                                              :app_genre => genres[options.genre][:name])
                        end
                    rescue => detail
                        warn detail
                        warn detail.backtrace.join("\n")
                        warn "Failed to insert app; #{csv_row.to_s}"
                    end
                end
            end
        end
    end

    # Wait for all indexing to finish
    threads.each do |thread|
        thread.join
    end

    # Sort the result and print them out line by line
    result.sort { |x, y|
        x[:index] <=> y[:index]
    }.each do |result|
        puts result[:result]
    end
end
