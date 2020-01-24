class DetailsEditor
  constructor: (@venueResultElement, attach) ->
    @venueresult = @venueResultElement.venueresult # For convenience
    @setupEditPopover(attach)

  editChanged: (popover, element, changed) ->
    changed = changed && !$(element).hasClass("error")
    $(element).toggleClass("changed", changed).parents(".control-group").toggleClass("success", changed)

    disablesubmit = popover.find(".submittable.changed").not(".venuedetails_comment").not(".error").length == 0
    popover.find(".submitbtn").toggleClass('disabled', disablesubmit)

    # enable/disable venuelinks, set hrefs
    popover.find(".twitter-link").toggleClass('disabled', popover.find(".venuedetails_twitter").val().trim().length == 0)
           .attr("href",  "http://twitter.com/#{encodeURIComponent(popover.find(".venuedetails_twitter").val().trim())}")
    popover.find(".facebook-link").toggleClass('disabled', popover.find(".venuedetails_facebook").val().trim().length == 0)
           .attr("href",  popover.find(".venuedetails_facebook").val().trim())
    popover.find(".facebook-link").toggleClass('disabled', popover.find(".venuedetails_facebook").val().trim().length == 0)
           .attr("href",  popover.find(".venuedetails_facebook").val().trim())
    popover.find(".instagram-link").toggleClass('disabled', popover.find(".venuedetails_instagram").val().trim().length == 0)
           .attr("href",  "https://instagram.com/#{encodeURIComponent(popover.find(".venuedetails_instagram").val().trim())}")
    popover.find(".googlesearch")
           .attr("href", "https://www.google.com/search?q=#{encodeURIComponent(popover.find(".venuedetails_name").val())}" +
                         "+#{encodeURIComponent(popover.find(".venuedetails_address").val())}" +
                         "+#{encodeURIComponent(popover.find(".venuedetails_city").val())}" +
                         "+#{encodeURIComponent(popover.find(".venuedetails_state").val())}")

    urlval = popover.find(".venuedetails_url")?.val()?.trim()
    if urlval?.length > 0
      urlval = "http://" + urlval unless (urlval.match(/https?:\/\//))
      popover.find(".webpage-url-link").removeClass("disabled").attr("href", "#{urlval}")
    else
      popover.find(".webpage-url-link").addClass("disabled")

    menuurl = popover.find(".venuedetails_menuUrl")?.val()?.trim()
    if urlval?.length > 0
      urlval = "http://" + urlval unless (menuurl.match(/https?:\/\//))
      popover.find(".webpage-menuurl-link").removeClass("disabled").attr("href", "#{menuurl}")
    else
      popover.find(".webpage-menuurl-link").addClass("disabled")

  setupParentEditor: (popover) ->
    popover.find(".venuedetails_parentId").select2
      placeholder: "Search for parent venue"
      minimumInputLength: 3
      allowClear: true
      initSelection: (element, callback) =>
        parent = @venueresult.venuedata.parent
        if parent
          callback
            id: parent.id
            text: parent.name
            object: parent
      formatResult: (object, container, query) =>
        HandlebarsTemplates['venues/edit_venue_details/parentcandidate']({candidate: object.object, venue: @venueresult.venuedata})
      formatSelection: (object, container) =>
        HandlebarsTemplates['venues/edit_venue_details/parentcandidate']({candidate: object.object, venue: @venueresult.venuedata})
      sortResults: (results, container, query) =>
        results.sort (a, b) =>
          a.object?.location?.distance - b.object?.location?.distance
      formatResultCssClass: (object) ->
        if object.object?.location?.distance > 1000
          "distance-warning"
      ajax:
        url: (term, page) ->
          if term.match(/^ *([0-9a-f]{24}) *$/)
            venueid = term.match(/^ *([0-9a-f]{24}) *$/)[1]
            "https://api.foursquare.com/v2/venues/#{venueid}"
          else
            "https://api.foursquare.com/v2/venues/suggestcompletion"
        dataType: "json"
        data: (term, page) =>
          if term.match(/^ *([0-9a-f]{24}) *$/)
            oauth_token: token
            v: API_VERSION
            m: 'swarm'
          else
            ll: @venueresult.venuedata.location.lat + "," + @venueresult.venuedata.location.lng
            query: term
            oauth_token: token
            v: API_VERSION
            m: 'swarm'
        results: (data, page) =>
          # FIXME: replace with custom display
          results: if data.response.minivenues
              data.response.minivenues.map (e) =>
                id: e.id
                text: e.name
                object: e
              .filter (e) => e.id != @venueresult.id
            else
              [{id: data.response.venue.id, text: data.response.venue.name, object: data.response.venue}]
          more: false

  setupMapEditor: (popover) ->
    # Only load Google Maps if actually tabbed to, and then only do it once
    mapsInitialized = false
    venuedata = @venueresult.venuedata
    self = this
    popover.find("a[href=#relocate]").on('shown', (e) ->
      return if mapsInitialized
      relocateMap = new google.maps.Map document.getElementById("relocateMap"),
        zoom: 17
        center: new google.maps.LatLng(venuedata.location.lat, venuedata.location.lng)
        mapTypeId: google.maps.MapTypeId.ROADMAP
        mapTypeControl: true
        zoomControl: true
        zoomControlOptions:
          position: google.maps.ControlPosition.LEFT_CENTER
          style: google.maps.ZoomControlStyle.LARGE

      oldVenueMarker = new google.maps.Marker
        map: relocateMap
        draggable: false
        position: new google.maps.LatLng(venuedata.location.lat, venuedata.location.lng)
        title: venuedata.name + " (current location)"
        zindex: -50
        icon: '/img/gray-mapicon.png'

      venueMarker = new google.maps.Marker
        position: new google.maps.LatLng(venuedata.location.lat, venuedata.location.lng)
        map: relocateMap
        draggable: true
        title: venuedata.name


      setNewPosition = (position) ->
        venueMarker.setPosition(position)
        popover.find(".venuedetails_controlgroup").removeClass('error')
        popover.find(".venuedetails_ll").val(position.lat() + "," + position.lng()).removeClass('error').trigger('change')
        if (!relocateMap.getBounds().contains(position))
          relocateMap.fitBounds(relocateMap.getBounds().extend(position))

      google.maps.event.addListener(relocateMap, 'click', (e) ->
        setNewPosition(e.latLng)
      )

      google.maps.event.addListener(venueMarker, 'dragend', (e) ->
        setNewPosition(venueMarker.getPosition())
      )

      popover.find(".venuedetails_ll").blur (e) ->
        val = popover.find(".venuedetails_ll").val()
        [latstring, lngstring] = val.split(',')
        [lat, lng] = [parseFloat(latstring), parseFloat(lngstring)]
        isFloat = (s) ->
          /^(\-|\+)?([0-9]+(\.[0-9]+)?)$/.test(s)

        if (isFloat(lat) && isFloat(lng) && lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0)
          setNewPosition(new google.maps.LatLng(lat, lng), false)
        else
          popover.find(".venuedetails_ll").addClass('error')
          popover.find(".venuedetails_controlgroup").addClass('error')

      mapsInitialized = true
    )

  setupHoursEditor: (popover) ->
    timeoutId = null
    oldtext = null
    popover.find(".hours-freeform").on "keyup paste change", (e) =>
      window.clearTimeout(timeoutId) if timeoutId
      timeoutId = window.setTimeout(() =>
        text = popover.find(".hours-freeform").val()
        return if text  == oldtext
        oldtext = text
        hours = Hours.parse(text)

        if hours
          hours.validateForVenue(@venueresult.id,
            success: (data) =>
              @updateHoursField(popover, data, hours)
            error: () ->
              data:
                status: "ERROR"
                message: "Could not verify hours."
              @updateHoursField(popover, data, hours)
          )
        else
          @updateHoursField(popover, {status: "OK", hours: []}, new Hours([]))
      , 200)

  updateHoursField: (popover, response, hours) ->
    popover.find("input.venuedetails_hours").toggleClass("error", response.status == "ERROR")
    popover.find("input.venuedetails_hours").val(hours.asProposedEdit()).trigger('change')
    popover.find(".existinghours").html(Handlebars.partials['venues/edit_venue_details/_humanhours'](response))

  setupEditPopover: (attach) ->
    self = this
    attach.popover
      html: true
      trigger: 'click'
      placement: "right"
      title: () => "Edit Details for place: <em><a target='_blank' href='https://foursquare.com/venue/#{@venueresult.id}'>#{@venueresult.venuedata.name}</a></em>" + " <button class='popover-close close pull-right'>&times;</button>"
      content: () => HandlebarsTemplates['venues/edit_venue_details/edit_venue_details']
                      venue: @venueresult.venuedata
                      hours: @venueresult.hours
                      hoursProposedEdit: @venueresult.hours.asProposedEdit()

      container: ".attach-popover"
      template: '<div class="popover ontop superwide"><div class="arrow"></div><div class="popover-inner"><h3 class="popover-title"></h3><div class="popover-content"><p></p></div></div></div>'
    .on "shown", (e) =>
      if $(e.target).hasClass('disabled')
        $(e.target).popover('hide')
        return
      attach.addClass('active')
      BootstrapUtils.repositionPopover($(e.target).data('popover'))
      $(".open-popover").not(e.target).popover('hide')
      $(e.target).addClass("open-popover")
      popoverobj = $(e.target).data('popover')
      popover = popoverobj.tip()
      popover.find(".popover-close").click (e) ->
        e.preventDefault()
        popoverobj.hide()
      popover.find(".venueedit .submittable").on 'keyup paste change', (e) ->
        window.setTimeout( #Paste needs a timeout, since the event fires before the element is changed
          () =>
            if (original = $(e.target).data('originalvalue'))
              changed = original.replace("empty","") != e.target.value
            else
              changed = e.target.defaultValue.trim() != e.target.value.trim()
            self.editChanged(popover, this, changed)
          , 20
        )
      popover.find(".venueedit .submittable").trigger("keyup")
      popover.find(".editpopoverexternal").click (e) ->
        return false if $(this).hasClass("disabled")

      popover.find(".submitbtn").click (e) ->
        e.preventDefault()
        return if $(this).hasClass("disabled")
        edits = {'oldvalues': {}, 'newvalues': {}}
        for i in popover.find(".submittable.changed").not(".error")
          if (original = $(i).data('originalvalue'))
            edits.oldvalues[$(i).data('keyname')] = $(i).data('originalvalue').replace("empty",'')
          else
            edits.oldvalues[$(i).data('keyname')] = i.defaultValue
          edits.newvalues[$(i).data('keyname')] = i.value

        editflag = self.venueresult.createFlag "EditVenueFlag",
          edits: edits
          comment: popover.find(".venuedetails_comment").val()

        FlagSubmissionService.get().submitFlags [editflag], new VenueSubmitListener(self.venueResultElement)
        popoverobj.hide()

      @setupParentEditor(popover)
      @setupHoursEditor(popover)
      @setupMapEditor(popover)

    .on "hidden", (e) ->
      attach.removeClass('active')
      $(e.target).removeClass("open-popover")

window.DetailsEditor = DetailsEditor
