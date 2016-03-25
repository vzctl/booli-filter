#!/usr/bin/env ruby

require './booli'
require 'active_support/all'
require 'google_maps_api/directions'
require 'haml'
require 'erb'
require 'chronic'

def config
  @file ||= YAML.load_file('config.yaml').symbolize_keys
end

def transit_options
  return @transit_options if @transit_options
  @transit_options = config[:transit_options].symbolize_keys.merge(departure_time: Chronic.parse(config[:departure_time]))
end

def cache_fetch(name, key)
  ActiveSupport::Cache.lookup_store(:file_store, "./.cache/#{name}").fetch(key) { yield }
end

def route(origin, destination)
  leg = cache_fetch('route', [transit_options] + origin + [destination]) do
    directions = GoogleMapsAPI::Directions.route([origin], [destination], transit_options)
    directions.routes.first.legs.first rescue []
  end
  summary = leg.steps[0..-2].map { |s| [s.distance, s.duration, s.html_instructions].join(', ') }.join(' | ')
  ["#{leg.duration.text}:  #{summary}", leg]
end

query = config[:booli]['query']
query_sold = query.merge(minLivingArea:  query['minLivingArea'] - 10,
                   minSoldDate: 6.months.ago.monday.strftime('%Y%m%d'),
                   dim: '200,200')

if config[:maps_key]
  polygons = []
  config[:bboxes].each do |name, coords|
    polygon = []
    polygon << [coords[0], coords[1]]
    polygon << [coords[0], coords[3]]
    polygon << [coords[2], coords[3]]
    polygon << [coords[2], coords[1]]
    polygon << [coords[0], coords[1]]
    polygons << polygon
  end
  File.write('map.html', ERB.new(File.read('map.html.erb')).result(binding))
end

results = Hash.new { |h, k| h[k] = [] }

config[:bboxes].each do |name, bbox|
  params = query.dup
  params[:bbox] = bbox.join(',')
  booli = Booli.new('listings', params, config[:booli])
  fail 'increase limit' if booli.fetch['count'] != booli.fetch['totalCount']
  booli.each do |a|
    next if a['floor'].to_i < config[:minimal_floor]
    a['coordinates'] = [a['location']['position']['latitude'], a['location']['position']['longitude']]
    a['address'] = a['location']['address']['streetAddress']
    a['routes'], skip = {}, false
    config[:transit_limits].each do |dst, mins|
      next if skip
      a['routes'][dst], leg = route(a['coordinates'], dst)
      skip = true if leg.duration.value > mins * 60
      skip = true if leg.steps.first.distance.value > config[:walking_distance_limit]
    end
    next if skip
    params_sold  = query_sold.dup
    params_sold[:maxLivingArea] = a['livingArea'] + 10
    params_sold[:minLivingArea] = a['livingArea']
    params_sold[:center] = a['coordinates'].join(',')
    a['sold'] = cache_fetch('sold', params_sold) { Booli.new('sold', params_sold, config[:booli]).list }
    results[name] << a
  end
end

File.write('list.html', Haml::Engine.new(File.read('list.html.haml')).render(binding))
