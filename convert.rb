# frozen_string_literal: true

require 'nokogiri'
require 'csv'

builder = Nokogiri::XML::Builder.new do |xml|
  xml.gpx(version: '1.1', creator: 'https://github.com/DawidJanczak/opencell_csv_to_gpx') do |gpx|
    CSV.foreach(ARGF.file, headers: true) do |row|
      if row['radio'] == 'LTE'
        gpx.wpt(lat: row['lat'], lon: row['lon']) do |wpt|
          wpt.type { |t| t.text row['radio'] }
        end
      end
    end
  end
end

File.write('stations.gpx', builder.to_xml)
