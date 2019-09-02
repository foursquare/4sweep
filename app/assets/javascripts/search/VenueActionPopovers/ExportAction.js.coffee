#= require search/VenueActionPopovers/VenueActionPopover

class ExportAction extends VenueActionPopover
  requireSelectedCount: 1
  template: "explore/massflags/export"

  userCreatedLists: (options = {}) ->
    return options.success?(@createdListCache) if @createdListCache
    $.ajax
      url: "https://api.foursquare.com/v2/users/self/lists"
      data:
        oauth_token: token
        v: API_VERSION
        m: 'swarm'
        group: 'created'
        limit: 200
        offset: 0
      success: (data) =>
        @createdListCache = data.response.lists.items
        options.success?(@createdListCache)
      error: options.error?

  title: () ->
    "Export <span class='selectedcount'>#{@selectedcount}</span> place(s):"

  tooltipTitle: () -> "Export Selected Items"

  openGeneratedLink: (options = {}) ->
    link = document.createElement "a"
    link.download = options.download if options.download
    link.href = options.href
    link.target = options.target if options.target

    # Firefox needs it attached to the doc
    popover = @trigger.data('popover')?.tip()
    popover.find(".linkdump").append(link)
    link.click()
    popover.find(".linkdump").html("")

  contentExtras: () ->
    for own id, element of @explorer.selected
      querytext = element.venueresult.venuedata.name
      break
    dupquery: querytext

  showPopover: (e) ->
    super(e)
    popover = @trigger.data('popover')?.tip()
    self = this

    @userCreatedLists
      success: (lists) ->
        popover.find(".list-chooser").select2
          data: lists.map (list) -> {id: list.id, text: list.name, list: list}
          placeholder: "Choose a list"
        popover.find(".loadinglists").hide()

        popover.find(".list-chooser").on "change", () => popover.find(".addaction").removeClass('disabled')

      error: () ->
        popover.find(".error").removeClass("hide").text("Could not load your lists")

    popover.find(".addaction").click (e) ->
      e.preventDefault()
      return if $(this).hasClass("disabled")
      self.addSelectedToList(popover.find('.list-chooser').select2('data'))

    popover.find(".exportvenueids").click (e) ->
      e.preventDefault()
      return if $(this).hasClass("disabled")
      self.exportVenueIds()
      self.deselectAndHide()

    popover.find(".exportvenuecsv").click (e) ->
      e.preventDefault()
      return if $(this).hasClass("disabled")
      self.exportCSV()
      self.deselectAndHide()

    popover.find(".searchfordups").click (e) ->
      e.preventDefault()
      self.searchForDuplicates()
      self.deselectAndHide()

    popover.find(".elioupload").click (e) ->
      e.preventDefault()
      self.openInElio()
      self.deselectAndHide()

  deselectAndHide: () ->
    for id, venueelement of @explorer.selected
      venueelement.toggleSelection(false)
    @trigger.popover("hide")

  addSelectedToList: (list) ->
    for own venueid, venueelement of @explorer.selected
      do (venueid, venueelement) =>
        $.ajax
          type: "POST"
          url: "https://api.foursquare.com/v2/lists/#{list.id}/additem"
          data:
            m: 'swarm'
            v: API_VERSION
            oauth_token: token
            venueId: venueid
          success: (data) =>
            @trigger.popover('hide')
            venueelement.toggleSelection(false)
            @notifyWithTimeout(data.response.item, list.list, true)
          error: (xhr, textStatus, errorThrown) =>
            @notifyWithTimeout({venue: venueelement.venueresult.venuedata}, list.list, false)
            venueelement.toggleSelection(false)
            @trigger.popover('hide')

  notifyWithTimeout: (listItem, listObj, success) ->
    # FIXME: add timeout and grouping?
    $.pnotify
      text: HandlebarsTemplates['explore/massflags/addlist_confirm']({venue: listItem.venue, list: listObj, success: success}).replace(/[\n\r]/,"")
      type: if success then "success" else "error"
      stack: STACK_BOTTOMRIGHT
      addclass: "stack-bottomright"
      icon: false
      width: "450px"

  searchForDuplicates: () ->
    locations = for own id, element of @explorer.selected
      venuedata = element.venueresult.venuedata
      parseFloat(venuedata.location.lat).toFixed(6) + "," + parseFloat(venuedata.location.lng).toFixed(6)

    popover = @trigger.data('popover')?.tip()
    query = popover.find('.dupquery').val()

    @openGeneratedLink
      target: "_blank"
      href: "#s=dupsearch&q=#{encodeURIComponent(query)}&locations=#{locations.join(';')}"

  exportVenueIds: () ->
    data = (id for own id, element of @explorer.selected)
    @openGeneratedLink
      download: "4sweep_export.txt"
      href: "data:text/plain;charset=utf-8," + encodeURIComponent(data.join("\n"))

  openInElio: () ->
    data = (id for own id, element of @explorer.selected)
    chunkedData = (data.splice(0, 250) while data.length)
    for d, i in chunkedData
      @openGeneratedLink
        target: "_blank"
        href: "http://4sq.eliotools.site/load.php?venues=" + d.join(",")

  exportCSV: () ->
    header = [
      'venue',
      'name',
      'address',
      'crossStreet',
      'city',
      'state',
      'zip',
      'twitter',
      'phone',
      'url',
      'description',
      'venuell',
      'categoryId',
      'facebook'
    ]

    data = for own id, element of @explorer.selected
      venuedata = element.venueresult.venuedata
      [
        venuedata.id,
        venuedata.name,
        venuedata.location.address,
        venuedata.location.crossStreet,
        venuedata.location.city,
        venuedata.location.state,
        venuedata.location.postalCode,
        venuedata.contact.twitter,
        venuedata.contact.phone,
        venuedata.url,
        venuedata.description,
        venuedata.location.lat + "," + venuedata.location.lng,
        venuedata.categories[0]?.id,
        venuedata.contact.facebookUsername || venuedata.contact.facebook
      ]

    csv = header.join(";") + "\n"
    csv += data.map (row) ->
      row.map (field) ->
        field = (field || "").replace(/\\/g, '\\\\')
        field = field.replace(/"/g,'\\"')
        "\"#{field}\""
      .join(";")
    .join("\n")

    @openGeneratedLink
      download: "4sweep_export.csv"
      href: "data:text/csv;charset=UTF-8," + window.encodeURIComponent(csv)

window.ExportAction = ExportAction
