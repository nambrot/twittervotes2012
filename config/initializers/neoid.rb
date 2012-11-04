require 'neography'

ENV["NEO4J_URL"] ||= "http://localhost:7474"

uri = URI.parse(ENV["NEO4J_URL"])

$neo = Neography::Rest.new(uri.to_s)

Neoid.db = $neo