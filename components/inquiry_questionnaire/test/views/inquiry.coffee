benv = require 'benv'
sinon = require 'sinon'
Backbone = require 'backbone'
setup = require './setup'
Inquiry = benv.requireWithJadeify require.resolve('../../views/inquiry'), [
  'template'
]

describe 'Inquiry', setup ->
  describe '#render', ->
    describe 'user with email and name', ->
      beforeEach ->
        @view = new Inquiry
          user: @currentUser
          artwork: @artwork
          inquiry: @inquiry
          state: @state

        @view.render()

      it 'renders the template', ->
        @view.$('h1').text()
          .should.equal 'Send message to gallery'
        @view.$('.scontact-description').text()
          .should.equal 'To: Gagosian Gallery'
        @view.$('input[type="text"][name="name"]')
          .should.have.lengthOf 0
        @view.$('input[type="email"][name="email"]')
          .should.have.lengthOf 0
        @view.$('.scontact-from').text()
          .should.equal 'From: Craig Spaeth (craigspaeth@gmail.com)'

    describe 'user without contact details', ->
      beforeEach ->
        @loggedOutUser.unset 'name'
        @loggedOutUser.unset 'email'

        @view = new Inquiry
          user: @loggedOutUser
          artwork: @artwork
          inquiry: @inquiry
          state: @state

        @view.render()

      it 'renders the template', ->
        @view.$('h1').text()
          .should.equal 'Send message to gallery'
        @view.$('.scontact-description').text()
          .should.equal 'To: Gagosian Gallery'
        @view.$('input[type="text"][name="name"]')
          .should.have.lengthOf 1
        @view.$('input[type="email"][name="email"]')
          .should.have.lengthOf 1
        @view.$('.scontact-from').text()
          .should.be.empty()

  describe 'next', ->
    beforeEach ->
      sinon.stub Backbone, 'sync'

      @state.set 'steps', ['inquiry', 'after_inquiry']

      @loggedOutUser.unset 'name'
      @loggedOutUser.unset 'email'

      @view = new Inquiry
        user: @loggedOutUser
        artwork: @artwork
        inquiry: @inquiry
        state: @state

      @view.render()

    afterEach ->
      Backbone.sync.restore()

    it 'sets up the inquiry and ensures the user has contact details', (done) ->
      @view.$('input[name="name"]').val 'Foo Bar'
      @view.$('input[name="email"]').val 'foo@bar.com'
      @view.$('textarea[name="message"]').val 'I wish to buy the foo bar'
      @view.$('button').click()

      # Sets up the inquiry
      @inquiry.get('message').should.equal 'I wish to buy the foo bar'
      @inquiry.get('contact_gallery').should.be.true()
      @inquiry.get('artwork').should.equal @artwork.id

      # Sets up the user
      @loggedOutUser.get('name').should.equal 'Foo Bar'
      @loggedOutUser.get('email').should.equal 'foo@bar.com'

      Backbone.sync.callCount.should.equal 2

      Backbone.sync.args[0][1].url()
        .should.containEql '/api/v1/me/artwork_inquiry_request'
      Backbone.sync.args[1][1].url()
        .should.containEql "/api/v1/me/anonymous_session/#{@loggedOutUser.id}"

      @wait =>
        # Next
        @view.state.current().should.equal 'after_inquiry'

        done()
