_                 = require 'underscore'
benv              = require 'benv'
Backbone          = require 'backbone'
sinon             = require 'sinon'
PersonalizeState  = require '../../client/state'
CurrentUser       = require '../../../../models/current_user'
Items             = require '../../../../collections/items'
Profile           = require '../../../../models/profile'
{ fabricate }     = require 'antigravity'
{ resolve }       = require 'path'
Followable        = require '../../client/mixins/followable'

SuggestionsView   = benv.requireWithJadeify resolve(__dirname, '../../client/views/suggestions'), ['suggestedTemplate']
GalleriesView     = benv.requireWithJadeify resolve(__dirname, '../../client/views/galleries'), ['template']

# Hack for inherited compiled jade templates
GalleriesView::suggestedTemplate = SuggestionsView::suggestedTemplate

describe 'SuggestionsView', ->
  before (done) ->
    benv.setup =>
      benv.expose $: benv.require 'jquery'
      Backbone.$ = $
      done()

  after ->
    benv.teardown()

  beforeEach ->
    @user   = new CurrentUser fabricate 'user', location: city: 'New York'
    @state  = new PersonalizeState user: @user
    @view   = new GalleriesView(state: @state, user: @user, followKind: 'artist')

    sinon.stub GalleriesView::, 'setupSearch'
    profiles = _.times 4, -> fabricate('partner_profile', id: _.uniqueId 'profile_')
    sinon.stub(Backbone, 'sync').yieldsTo('success', profiles)

    @view.render()

  afterEach ->
    Backbone.sync.restore()
    @view.setupSearch.restore()

  describe '#initialize', ->
    it 'sets up following with the appropriate kind', ->
      @view.following.kind.should.equal 'profile'

  describe '#render', ->
    it 'renders the template', ->
      html = @view.$el.html()
      html.should.include 'Follow galleries on Artsy'
      html.should.include 'Receive notifications on upcoming shows and fairs'
      html.should.include 'Type your favorite gallery name'
      html.should.include 'Below are galleries we think you’ll enjoy based on artists you follow and your location,'
      html.should.include 'New York'

  describe '#ensureLocation', ->
    beforeEach ->
      sinon.stub @view.user, 'approximateLocation'
    afterEach ->
      @view.user.approximateLocation.restore()

    it 'ensures the user has a location', ->
      @view.user.approximateLocation.called.should.be.false
      @view.user.unset 'location'
      @view.ensureLocation()
      @view.user.approximateLocation.called.should.be.true
      @view.user.set 'location', city: 'Susquehanna'
      @view.user.approximateLocation.args[0][0].success()
      @view.$el.html().should.include 'Susquehanna'

  describe '#setup', ->
    beforeEach ->
      sinon.stub @view.following, 'followAll'
      sinon.stub @view.following, 'unfollowAll'
      @view.setup()

    afterEach ->
      @view.following.followAll.restore()
      @view.following.unfollowAll.restore()

    it 'fetches the suggestions', ->
      Backbone.sync.args[0][0].should.equal 'read'
      Backbone.sync.args[0][1].url.should.include '/api/v1/me/suggested/profiles'

    describe '#renderSuggestions', ->
      it 'renders the suggestions', ->
        html = @view.$el.html()
        html.should.include 'Gagosian Gallery'
        html.should.include 'The J. Paul Getty Trust is a cultural and philanthropic institution'
        @view.$('.grid-item').length.should.equal 4
        @view.$('.follow-button').length.should.equal 4

      it 'should be able to find corresponding els', ->
        @view.suggestions.map (model) =>
          @view.$suggestions.find(".follow-button[data-id='#{model.id}']").length.should.equal 1

      it 'sets the data state of the container to loaded', ->
        @view.$container.data('state').should.equal 'loaded'

      it 'creates corresponding FollowButton views', ->
        views = @view.suggestions.map (model) =>
          @view.followButtonViews[model.id].constructor.name
        views.length.should.equal @view.suggestions.length
        _.uniq(views)[0].should.equal 'FollowButton'

      it 'sets up a listener for setting the skip label', ->
        @view.__labelSet__?.should.not.be.ok
        @view.$('.personalize-skip').text().should.equal 'Skip'
        @view.$suggestions.find('.follow-button').first().click()
        @view.__labelSet__.should.be.ok
        @view.$('.personalize-skip').text().should.equal 'Next'

    describe '#unfollowAll', ->
      it 'unfollows anything in the following collection', ->
        @view.following.follow 'foo'
        @view.following.follow 'bar'
        @view.following.unfollowAll.called.should.be.false
        @view.$('#personalize-suggestions-unfollow-all').click()
        @view.following.unfollowAll.called.should.be.true
        @view.following.unfollowAll.args[0][0].should.eql ['foo', 'bar']

    describe '#remove', ->
      it 'tears down the view when there are extra things to tear down', ->
        @view.searchBarView       = remove: sinon.stub()
        @view.locationRequests    = [abort: sinon.stub()]
        @view.followButtonViews   = { view: remove: sinon.stub() }
        @view.remove()
        @view.searchBarView.remove.called.should.be.true
        @view.locationRequests[0].abort.called.should.be.true
        @view.followButtonViews.view.remove.called.should.be.true

      it 'tears down the view when there are not extra things to tear down', (done) ->
        @view.searchBarView       = undefined
        @view.locationRequests    = []
        @view.followButtonViews   = undefined
        @view.remove()
        done()
