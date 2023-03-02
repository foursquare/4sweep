Handlebars.registerHelper 'categoryIconUrl', (categories, size) ->
  if categories.length > 0
    "#{categories[0].icon.prefix}#{size}#{categories[0].icon.suffix}"
  else
    "https://foursquare.com/img/categories_v2/none_#{size}.png"

Handlebars.registerHelper 'categoryTitle', (categories) ->
  if categories.length > 0
    categories[0].name
  else
    "No Category"

Handlebars.registerHelper 'ratioText', () ->
  if @venue.stats.usersCount == 0
    " - "
  else
    (@venue.stats.checkinsCount / (@venue.stats.usersCount)).toFixed(1)

Handlebars.registerHelper 'ratioClass', () ->
  if @venue.stats.usersCount == 0
    ratio = " - "
  else
    ratio = (@venue.stats.checkinsCount / (@venue.stats.usersCount)).toFixed(1)

  ratioClass = 'label-success'
  ratioClass = 'label-warning' if ratio > 3 or @venue.stats.usersCount < 15
  ratioClass = 'label-important' if ratio > 10 or @venue.stats.usersCount < 5
  ratioClass = 'label-success' if @venue.stats.usersCount > 50
  ratioClass

Handlebars.registerHelper 'timeFromMongoId', (oid) ->
  timestamp = parseInt(oid.slice(0,8), 16)
  moment(timestamp * 1000).calendar() + " (" + moment(new Date(timestamp*1000)).fromNow() + ")"

Handlebars.registerHelper 'timeFromCreatedAt', (createdAt) ->
  timestamp = parseInt(createdAt)
  moment(timestamp * 1000).calendar() + " (" + moment(new Date(timestamp*1000)).fromNow() + ")"

Handlebars.registerHelper 'moment', (timeVal) ->
  time = if timeVal * 1000 then timeVal * 1000 else timeVal
  moment(time).calendar()

Handlebars.registerHelper 'moment-ago', (timeVal) ->
  time = if timeVal * 1000 then timeVal * 1000 else timeVal
  moment(time).fromNow()

Handlebars.registerHelper 'count', (items, options) ->
  items.length

Handlebars.registerHelper 'location', (location, options) ->
  if location.city or location.state or location.country
    if location.state
      ((location.city || "") + " " + location.state).trim()
    else
      ((location.city || "") + " " + (location.country || "")).trim()
  else
    "Unknown Location"

Handlebars.registerHelper 'replace', (subject, from, to) ->
  subject.split(from).join(to)

Handlebars.registerHelper 'plus', (op1, op2) ->
  op1 + op2

Handlebars.registerHelper 'stringify', (obj) ->
  JSON.stringify obj

Handlebars.registerHelper 'ifany', (objs..., content) ->
  success = false
  success = (success || val) for val in objs
  if success then content.fn(this) else content.inverse(this)

Handlebars.registerHelper 'ifall', (objs..., content) ->
  success = true
  success = (success && val) for val in objs
  if success then content.fn(this) else content.inverse(this)

Handlebars.registerHelper 'isin', (needle, objs..., content) ->
  success = false
  success = (success || needle == val) for val in objs
  if success then content.fn(this) else content.inverse(this)

Handlebars.registerHelper 'nl2separator', (content, separator) ->
  content.replace("\n", separator)

Handlebars.registerHelper 'formatFacebookHours', (hours, day) ->
  return "Closed" unless hours["#{day}_open"]
  toAmPm = (time) ->
    [hour, min] = time.split(/:/)
    conv = ((parseInt(hour) + 11) % 12 + 1)
    "#{conv}:#{min} " + if hour < 12 then "am" else "pm"

  span1 = toAmPm(hours["#{day}_open"]) + " – " + toAmPm(hours["#{day}_close"])

Handlebars.registerHelper 'pointDistance', (location1, location2) ->
  if google.maps.geometry.spherical.computeDistanceBetween
    meters = Math.round(google.maps.geometry.spherical.computeDistanceBetween(
      new google.maps.LatLng(location1.lat, location1.lng),
      new google.maps.LatLng(location2.lat, location2.lng)
    ))
    if meters < 1000
      meters + " m"
    else
      (meters/1000).toFixed(1) + " km"
  else
    return "Unknown"

Handlebars.registerHelper 'pointsDirection', (location1, location2) ->
  if google.maps.geometry.spherical.computeHeading
    degrees = google.maps.geometry.spherical.computeHeading(
      new google.maps.LatLng(location1.lat, location1.lng),
      new google.maps.LatLng(location2.lat, location2.lng)
    )
    dir = switch
      when degrees < -90 then "SW"
      when degrees < 0 then "NW"
      when degrees < 90 then "NE"
      when degrees >= 90 then "SE"
      else "Unknown"
    dir
  else
    "Unknown"

Handlebars.registerHelper 'round', (number) ->
  Math.round(number).toLocaleString()

Handlebars.registerHelper 'truncate', (str, len, separator = " ", continuation = "…", nl2br = false) ->
  filter = if nl2br then ((x) -> Handlebars.helpers['nl2br'](x)) else (x) -> x
  if (str && str.length > len && str.length > 0)
    new_str = str + separator
    new_str = str.substr(0, len)
    new_str = str.substr(0, new_str.lastIndexOf(separator))
    new_str = if (new_str.length > 0) then new_str else str.substr(0, len)

    filter(new_str + continuation)
  else
    filter(str)

Handlebars.registerHelper 'ifIsModPlus1', (op1, op2, options) ->
  if (op1 + 1) % op2 == 0
    options.fn(this)
  else
    options.inverse(this)

Handlebars.registerHelper 'uc', (str) ->
  if str
    encodeURIComponent(str)
  else
    ""

Handlebars.registerHelper "num", (val) ->
  if val?.toLocaleString
    val.toLocaleString()
  else
    val
