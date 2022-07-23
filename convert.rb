# frozen_string_literal: true

require 'nokogiri'
require 'csv'

# Areas are defined as bounding box going clockwise:
# North boundary, East, South, West
area = File.open('./bts.kml') { |f| Nokogiri::XML(f) }
area_coords = area.at('coordinates').text.strip.split(' ').map do |triple|
  triple.split(',')[0..1].map(&:to_f)
end

# Even-odd rule: https://en.wikipedia.org/wiki/Even%E2%80%93odd_rule
def point_in_polygon?(lon:, lat:, area_coords:)
  # in area_cords first and last element are the same so we can use each_cons(2)
  # and that will cover last + first
  area_coords.each_cons(2).inject(false) do |result, (prev_vertex, next_vertex)|
    # Point is a corner
    return true if next_vertex == [lon, lat]

    if lat < next_vertex[1] != lat < prev_vertex[1]
      # lies somewhere between the two points on lat/y plane, calculate slope
      slope = ((lon - next_vertex[0]) * (prev_vertex[1] - next_vertex[1])) -
              ((prev_vertex[0] - next_vertex[0]) * (lat - next_vertex[1]))

      # point is on boundary
      return true if slope.zero?

      # crosses polygon
      if slope.negative? != (prev_vertex[1] < next_vertex[1])
        !result
      else
        result
      end
    else
      result
    end
  end
end

already_added = Set.new

builder = Nokogiri::XML::Builder.new do |xml|
  xml.gpx(version: '1.1', creator: 'https://github.com/DawidJanczak/opencell_csv_to_gpx') do |gpx|
    CSV.foreach(ARGF.file, headers: true) do |row|
      lat, lon = row.values_at('lat', 'lon')
      next if already_added.include?([lat, lon])

      if row['radio'] == 'LTE' && point_in_polygon?(lon: lon.to_f, lat: lat.to_f, area_coords: area_coords)
        gpx.wpt(lat: lat, lon: lon) do |wpt|
          wpt.type { |t| t.text row['radio'] }
        end
        already_added << [lat, lon]
      end
    end
  end
end

File.write('stations.gpx', builder.to_xml)
