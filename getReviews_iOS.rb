#!/usr/bin/ruby

require 'optparse'
require 'ostruct'
require 'net/https'
require 'uri'
require 'nokogiri'
require 'sequel'
require "yaml"
require './utils/Options.rb'
require './utils/FileWriter.rb'

# Load options
countries = Options.parse_countries("options/countries.csv")

config = YAML.load_file("db_config.yaml")
DB = Sequel.connect(:adapter=>'postgres', :host=>config["host"], :database=>config["database"], :user=>config["user"], :password=>config["password"])
apps_table = DB[:apps]
reviews_table = DB[:reviews]

def printHelp
    puts "Usage: getReviews_iOS.rb FILE1 FILE2..."
end

# Applications to process
app_queue = Queue.new
app_count = {}

ARGV.each do |arg|
    if arg == "--help" || arg == "-h"
        printHelp
        exit
    else
        file_name = arg.dup
        puts "Fetching reviews for #{file_name.split('/')[-1][0..-5]}..."
        # Append "_reviews" to the end of the file name
        match_result = /\.[^\.]*$/.match(arg)
        unless match_result.nil?
            file_name.insert(match_result.begin(0), "_reviews")
        else
            file_name << "_reviews"
        end

        # Enumerate through list of applications
        CSV.read(arg, {:col_sep => "||", :quote_char => "\""}).each do |row|
            if row.length >= 4
                # Enqueue the application
                app_queue << { :target_file => file_name, :row => row }

                # Increment the application count for this file
                current_count = app_count[file_name]
                if current_count.nil?
                    current_count = 0
                end
                current_count += 1
                app_count[file_name] = current_count
            end
        end
    end
end

if app_queue.length == 0
    printHelp
    exit
end

file_writer = FileWriter.new

# 30 worker threads processing applications from the queue
threads = []
30.times do
    threads << Thread.new do
        # Open HTTP connection to the Apple's iTunes server
        Net::HTTP.start("itunes.apple.com", 80) do |http|
            until app_queue.empty?
                job = app_queue.pop(true) rescue nil
                row = job[:row]
                target_file = job[:target_file]

                unless row.nil? || target_file.nil?
                    store_front_id = countries[row[2].downcase]
                else
                    store_front_id = nil
                end

                unless store_front_id.nil?
                    # Get the actual store front ID string from the structure
                    store_front_id = store_front_id[:store_id]
                    page_num = 1
                    done = false

                    while !done
                        # Assume the there are no more pages. It gets set to true whenever it finds any reviews
                        done = true
                        # Generate request body
                        target_url = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/customerReviews?id=" + row[1] + "&displayable-kind=11&page=" + page_num.to_s
                        parsed_url = URI.parse(target_url)
                        # Error processing
                        finished = false
                        # Retry download until it succeeds
                        while !finished
                            finished = true
                            req = Net::HTTP::Get.new(parsed_url.request_uri)
                            req["X-Apple-Store-Front"] = store_front_id

                            begin
                                # Finally make the request
                                response = http.request(req)
                                response_code = Integer(response.code)
                                if response_code < 400 && !response.body.nil? && response.body.length > 0
                                    bodyHTML = response.body
                                    # Parse the HTML using Nokogiri
                                    html_doc = Nokogiri::HTML(bodyHTML)
                                    # Get all customer reviews for all versions
                                    divs = html_doc.xpath("//div[@class='paginate all-reviews']//div[@class='customer-review']")
                                    finished = !divs.nil?
                                else
                                    finished = false
                                    sleep(1)
                                end
                            rescue => detail
                                finished = false
                                sleep(1)
                            end
                        end

                        # Find customer reviews
                        divs.each do |review|
                            begin
                                # Found customer review
                                done = false

                                # Initialize all values to an empty string
                                review_title = ""
                                review_body = ""
                                review_star_rating = ""
                                review_author_name = ""
                                review_author_url = ""
                                app_version = ""
                                review_date = ""
                                review_id = ""

                                # Fetch the review title
                                review_title_dom = review.xpath(".//span[@class='customerReviewTitle']")
                                unless review_title_dom.nil? || review_title_dom.length == 0
                                    review_title = review_title_dom.text.strip
                                end

                                # Fetch the review content
                                review_text_dom = review.xpath(".//p[@class='content']")
                                unless review_text_dom.nil? || review_text_dom.length == 0
                                    review_text = review_text_dom.text.strip
                                end

                                # Fetch the rating
                                review_stars_dom = review.xpath(".//div[@class='rating']//span[@class='rating-star']")
                                unless review_stars_dom.nil? || review_stars_dom.length == 0
                                    review_stars = review_stars_dom.length.to_s
                                end

                                # Fetch the aurhor's details
                                review_author = review.xpath(".//span[@class='user-info']//a[@class='reviewer']")
                                unless review_author.nil? || review_author.length == 0
                                    review_author_name = review_author.text.strip
                                    review_author_url = review_author.attr("href").text.strip
                                end

                                # Fetch the reviewed version and date
                                review_misc_dom = review.xpath(".//span[@class='user-info']")
                                unless review_misc_dom.nil? || review_misc_dom.length == 0
                                    review_misc = review_misc_dom.text.strip

                                    # Fetch the version of application reviewed
                                    app_version_scan = /Version\s*(.*?)-\n/m.match(review_misc)
                                    unless app_version_scan.nil? || app_version_scan.length != 2
                                        app_version = app_version_scan[1].strip
                                    end

                                    # Fetch the date when it was reviewed
                                    review_misc_comps = review_misc.split("\n")
                                    review_date = review_misc_comps[-1].strip if review_misc_comps.length > 0
                                end

                                # Fetch the author's URL
                                review_report = review.xpath("./div[@class='report-a-concern']")
                                unless review_report.nil? || review_report.length == 0
                                    review_report_url = review_report.attr("report-a-concern-fragment-url").text.strip
                                    review_id_scan = /userReviewId=([0-9]+)/.match(review_report_url)
                                    # Fetch the review's unique ID
                                    unless review_id_scan.nil? || review_id_scan.length != 2
                                        review_id = review_id_scan[1]
                                    end
                                end

                                # Calculate word and character counts
                                title_word_count = review_title.to_s.split(" ").length
                                title_char_count = review_title.to_s.length
                                body_word_count = review_body.to_s.split(" ").length
                                body_char_count = review_body.to_s.length

                                csv_row = CSV::Row.new([], [row[1], 
                                                            review_id, 
                                                            review_date, 
                                                            app_version, 
                                                            title_word_count,
                                                            title_char_count,
                                                            body_word_count,
                                                            body_char_count,
                                                            review_star_rating, 
                                                            review_author_name, 
                                                            review_author_url,
                                                            review_title, 
                                                            review_body])
                                
                                # Format the csv string with || as delimiter
                                pipe_delimited_csv_row = CSV.generate(:col_sep => "||") do |csv|
                                    csv << csv_row
                                end

                                # Queue the file write to the file writer
                                file_writer.add_job(target_file, pipe_delimited_csv_row.to_s)

                                # Check if the app exists                 
                                begin
                                    reviews_table.insert(:review_id => review_id,
                                                   :app_id => row[1],
                                                   :review_date => review_date,
                                                   :app_version => app_version,
                                                   :review_author_name => review_author_name,
                                                   :review_author_url => review_author_url,
                                                   :review_title => review_title,
                                                   :review_body => review_body,
                                                   :review_star_rating => review_star_rating)
                                rescue => e
                                    # Foreign key constraint failure. App id not found in database
                                    warn e.message if not e.message.include? 'duplicate key'
                                end

                            rescue => detail
                                # Parsing error
                                warn detail
                                warn detail.backtrace.join("\n")
                            end
                        end

                        page_num = page_num + 1
                    end
                end
                
                # Finished processing this app
                remaining = app_count[target_file]
                unless remaining.nil?
                    remaining -= 1
                    app_count[target_file] = remaining
                    
                    # Tell the file writer to close the file when all jobs for certain file has finished
                    if remaining <= 0
                        file_writer.add_job(target_file, :terminate)
                    end
                end
            end
        end
    end
end

# Wait for scraping jobs to finish
threads.each do |thread|
    thread.join
end

# Wait for file writers to finish working
file_writer.wait_jobs
