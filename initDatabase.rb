require "yaml"
require "sequel"

# Connect to AppMiner database
config = YAML.load_file("db_config.yaml")
DB = Sequel.connect(:adapter=>'postgres', :host=>config["host"], :database=>config["database"], :user=>config["user"], :password=>config["password"])

# Create an apps table (if it doesn't already exist)
puts "Creating Apps table..." if not DB.table_exists?(:apps) 
DB.create_table? :apps do
	# Columns
	String :app_id
	String :app_version
	String :app_name
	String :app_url
	String :app_price
	String :app_currency
	String :app_size
	String :app_rank
	String :app_genre

	# Constraints
	primary_key [:app_id]
end

# Create a reviews table (if it doesn't already exist)
puts "Creating Reviews table..." if not DB.table_exists?(:reviews) 
DB.create_table? :reviews do
	# Columns
	String :review_id, :unique => true
	String :app_id
	String :app_version
	String :review_star_rating
	String :review_char_count
	String :review_word_count
	String :review_date
	String :review_author_name
	String :review_author_url
	String :review_title
	String :review_body

	# Constraints
	primary_key :review_id
	foreign_key [:app_id], :apps
end

# Print success and number of rows
apps = DB[:apps]
reviews = DB[:reviews]

puts "Apps table initialised. Current number of rows: #{apps.count}"
puts "Reviews table initialised. Current number of rows: #{reviews.count}"
