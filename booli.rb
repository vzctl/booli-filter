require 'digest/sha1'
require 'httparty'

class Booli
  include HTTParty
  format :json
  base_uri 'api.booli.se'
  default_params format: 'json', limit: 150
  # debug_output $stdout

  def self.default_options
    time = Time.new.strftime('%Y-%m-%dT%H:%M:%S%z')
    unique = '%.16x' % rand(9**20)
    auth = { callerId: @@config['appname'],
             hash: Digest::SHA1.hexdigest(@@config['appname'] + time + @@config['appkey'] + unique),
             time: time,
             unique: unique }
    @default_options[:default_params].update(auth)
    @default_options
  end

  attr_accessor :result, :query, :what

  def initialize(what, query, config)
    @what, @query, @@config = what, query, config
    fetch
  end

  def fetch(force=false)
    if @fetch.nil? || force
      query = @query.dup
      response = self.class.get("/#{what}", query: query)
      @fetch = response
    end
    @fetch
  end

  def each
    fetch[what].each { |r| yield r }
  end

  def list
    fetch[what]
  end
end
