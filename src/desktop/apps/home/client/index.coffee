Q = require 'bluebird-q'
Backbone = require 'backbone'
Cookies = require 'cookies-js'
metaphysics = require '../../../../lib/metaphysics.coffee'
mediator = require '../../../lib/mediator.coffee'
CurrentUser = require '../../../models/current_user.coffee'
HeroUnitView = require './hero_unit_view.coffee'
HomeAuthRouter = require './auth_router.coffee'
JumpView = require '../../../components/jump/view.coffee'
SearchBarView = require '../../../components/search_bar/view.coffee'
setupHomePageModules = require './setup_home_page_modules.coffee'
maybeShowBubble = require '../components/new_for_you/index.coffee'
setupArtistsToFollow = require '../components/artists_to_follow/index.coffee'
Articles = require '../../../collections/articles'
Items = require '../../../collections/items'
featuredArticlesTemplate = -> require('../templates/featured_articles.jade') arguments...
featuredShowsTemplate = -> require('../templates/featured_shows.jade') arguments...
{ resize } = require '../../../components/resizer/index.coffee'
sd = require('sharify').data

module.exports.HomeView = class HomeView extends Backbone.View
  initialize: ->
    # Set up a router for the /log_in /sign_up and /forgot routes
    new HomeAuthRouter
    Backbone.history.start pushState: true

    # Render Featured Sections
    if sd.HIDE_HERO_UNITS then @setupSearchBar() else @setupHeroUnits()
    @setupFeaturedShows()
    @setupFeaturedArticles()

  setupHeroUnits: ->
    new HeroUnitView
      el: @$el
      $mainHeader: $('#main-layout-header')

  setupFeaturedShows: ->
    featuredShows = new Items [], id: '530ebe92139b21efd6000071', item_type: 'PartnerShow'
    featuredShows.fetch().then (results) ->
        $("#js-home-featured-shows").html featuredShowsTemplate
          featuredShows: featuredShows
          resize: resize

  setupFeaturedArticles: ->
    featuredArticles = new Articles
    featuredArticles.fetch(
      data:
        published: true
        featured: true
        sort: '-published_at'
    ).then (results) ->
      $("#js-home-featured-articles").html featuredArticlesTemplate
        featuredArticles: featuredArticles
        resize: resize

  setupSearchBar: -> 
    @searchBarView = new SearchBarView
      el: @$('#main-layout-search-bar-container')
      $input: @$('#main-layout-search-bar-input')
      displayEmptyItem: true
      autoselect: true
      mode: 'suggest'
      limit: 7
    @searchBarView.on 'search:entered', (term) -> window.location = "/search?q=#{term}"
    @searchBarView.on 'search:selected', @searchBarView.selectResult


module.exports.init = ->
  user = CurrentUser.orNull()

  new HomeView el: $('body')

  setupHomePageModules()
  setupArtistsToFollow user
  maybeShowBubble user
