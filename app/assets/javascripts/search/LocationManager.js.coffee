class LocationManager
  constructor: (@map, @lastSearchLocation) ->
    @setupDrawing();
    unless @lastSearchLocation instanceof GlobalLocation
      @lastFiniteLocation = @lastSearchLocation
    @lastBoundedLocation = @lastSearchLocation if @lastSearchLocation.bounded

  setupDrawing: () ->
    @setupControls()
    @globalControl = new GlobalControl();
    @radiusControl = new RadiusDropdown()
    @nearControl = new NearButton()

    @radiusControl.elem.change (e) =>
      e.preventDefault()
      radius = @radiusControl?.val() || 25000
      extended = @lastBoundedLocation.extendToRadius(radius)
      shape = extended.drawingWithOptions({map: @map})
      @processLocationDraw(extended, shape)
      @globalControl.reset()
      @nearControl.close()

    @nearControl.elem.find("button.executeNear").click (e) =>
      e.preventDefault()
      @processLocationDraw(@nearControl.getGeoLocation())

    @globalControl.elem.children('div').on 'click', (e) =>
      @globalControl.select()
      @processLocationDraw(new GlobalLocation())
      @nearControl.close()

    google.maps.event.addListener @map, "click", (event) =>
      radius = @radiusControl.val()
      circle = new google.maps.Circle($.extend @circleOpts, {radius: radius, center: event.latLng, map: @map})
      @processLocationDraw(new CenterRadiusSearchLocation(event.latLng, radius), circle)
      @globalControl.reset()

  setupControls: (options = []) ->
    @map.controls[google.maps.ControlPosition.TOP_LEFT].clear()

    if "global" in options
      @map.controls[google.maps.ControlPosition.TOP_LEFT].push(@globalControl.control())

    if "near" in options
      @map.controls[google.maps.ControlPosition.TOP_LEFT].push(@nearControl.control())

  setGlobal: () ->
    @lastSearchLocation = new GlobalLocation()
    @globalControl.select()

  processLocationDraw: (location, shape = undefined) ->
    @lastSearchLocation.clear()
    @lastFiniteLocation?.clear()

    @lastSearchLocation = location
    @lastFiniteLocation = location unless location instanceof GlobalLocation
    @lastBoundedLocation = location if location.bounded
    search = @activeTab.performSearchAt @lastSearchLocation
    search.listeners.add 'resultsready geotoobig searchfailed', () ->
      shape?.setMap(null)

    if location instanceof NearGeoLocation
      search.listeners.add 'searchgeocoded', (geocode) =>
        @nearControl.setGeocode(geocode)
        @lastBoundedLocation = new BoundingBoxSearchLocation(
          new google.maps.LatLng(geocode.feature.geometry.bounds.ne.lat, geocode.feature.geometry.bounds.ne.lng),
          new google.maps.LatLng(geocode.feature.geometry.bounds.sw.lat, geocode.feature.geometry.bounds.sw.lng)
        )

  displaySearchLocation: (search) ->
    location = search.location
    @lastSearchLocation = location
    @lastFiniteLocation = location unless location instanceof GlobalLocation
    @lastBoundedLocation = location if location.bounded

    clearFunction = location.display
      map: @map
      nearControl: @nearControl
      globalControl: @globalControl
      radiusControl: @radiusControl

    search.listeners.add 'resultsready geotoobig searchfailed', () ->
      clearFunction()

  showControls: (actions) ->
    @setupControls(actions)

  location: (finiteOnly) ->
    if finiteOnly then @lastFiniteLocation else @lastSearchLocation

  setActiveTab: (@activeTab) ->

window.LocationManager = LocationManager
