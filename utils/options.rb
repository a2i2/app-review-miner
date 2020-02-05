#!/usr/bin/ruby
require 'csv'

class Options
    # List of available countries
    def self.parse_countries(filename)
        CSV.read(filename).inject({}) do |result, row|
            result[row[0].downcase] = { :name => row[1], :store_id => row[2] } if row.length == 3
            result
        end
    end

    # List of available feed types
    def self.parse_feed_types(filename)
        CSV.read(filename).map do |row|
            { :name => row[1], :short_name => row[2], :value => row[0] } if row.length == 3
        end
    end

    # List of available application genres
    def self.parse_genres(filename)
        CSV.read(filename).map do |row|
            { :name => row[1], :short_name => row[2], :value => row[0] } if row.length == 3
        end
    end
end
