_             = require 'underscore'
sd            = require('sharify').data
Backbone      = require 'backbone'
SearchResult  = require '../models/search_result.coffee'

module.exports = class Search extends Backbone.Collection

  model: SearchResult

  url: "#{sd.API_URL}/api/v1/match?visible_to_public=true"

  parse: (response, options) ->
    if options.res?.req
      sd.ARTSY_XAPP_TOKEN = options.res.req._headers['x-xapp-token']
    response

  updateLocationsForFair: (fair) ->
    @map (result) -> result.updateForFair fair
