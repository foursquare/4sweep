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

  setupTranslatedVenueNamesEditor: (popover) ->
    '''
    lang_list = [
        {"code":"ab","name":"Abkhaz","nativeName":"аҧсуа"},
        {"code":"aa","name":"Afar","nativeName":"Afaraf"},
        {"code":"af","name":"Afrikaans","nativeName":"Afrikaans"},
        {"code":"ak","name":"Akan","nativeName":"Akan"},
        {"code":"sq","name":"Albanian","nativeName":"Shqip"},
        {"code":"am","name":"Amharic","nativeName":"አማርኛ"},
        {"code":"ar","name":"Arabic","nativeName":"العربية"},
        {"code":"an","name":"Aragonese","nativeName":"Aragonés"},
        {"code":"hy","name":"Armenian","nativeName":"Հայերեն"},
        {"code":"as","name":"Assamese","nativeName":"অসমীয়া"},
        {"code":"av","name":"Avaric","nativeName":"авар мацӀ, магӀарул мацӀ"},
        {"code":"ae","name":"Avestan","nativeName":"avesta"},
        {"code":"ay","name":"Aymara","nativeName":"aymar aru"},
        {"code":"az","name":"Azerbaijani","nativeName":"azərbaycan dili"},
        {"code":"bm","name":"Bambara","nativeName":"bamanankan"},
        {"code":"ba","name":"Bashkir","nativeName":"башҡорт теле"},
        {"code":"eu","name":"Basque","nativeName":"euskara, euskera"},
        {"code":"be","name":"Belarusian","nativeName":"Беларуская"},
        {"code":"bn","name":"Bengali","nativeName":"বাংলা"},
        {"code":"bh","name":"Bihari","nativeName":"भोजपुरी"},
        {"code":"bi","name":"Bislama","nativeName":"Bislama"},
        {"code":"bs","name":"Bosnian","nativeName":"bosanski jezik"},
        {"code":"br","name":"Breton","nativeName":"brezhoneg"},
        {"code":"bg","name":"Bulgarian","nativeName":"български език"},
        {"code":"my","name":"Burmese","nativeName":"ဗမာစာ"},
        {"code":"ca","name":"Catalan; Valencian","nativeName":"Català"},
        {"code":"ch","name":"Chamorro","nativeName":"Chamoru"},
        {"code":"ce","name":"Chechen","nativeName":"нохчийн мотт"},
        {"code":"ny","name":"Chichewa; Chewa; Nyanja","nativeName":"chiCheŵa, chinyanja"},
        {"code":"zh","name":"Chinese","nativeName":"中文 (Zhōngwén), 汉语, 漢語"},
        {"code":"cv","name":"Chuvash","nativeName":"чӑваш чӗлхи"},
        {"code":"kw","name":"Cornish","nativeName":"Kernewek"},
        {"code":"co","name":"Corsican","nativeName":"corsu, lingua corsa"},
        {"code":"cr","name":"Cree","nativeName":"ᓀᐦᐃᔭᐍᐏᐣ"},
        {"code":"hr","name":"Croatian","nativeName":"hrvatski"},
        {"code":"cs","name":"Czech","nativeName":"česky, čeština"},
        {"code":"da","name":"Danish","nativeName":"dansk"},
        {"code":"dv","name":"Divehi; Dhivehi; Maldivian;","nativeName":"ދިވެހި"},
        {"code":"nl","name":"Dutch","nativeName":"Nederlands, Vlaams"},
        {"code":"en","name":"English","nativeName":"English"},
        {"code":"eo","name":"Esperanto","nativeName":"Esperanto"},
        {"code":"et","name":"Estonian","nativeName":"eesti, eesti keel"},
        {"code":"ee","name":"Ewe","nativeName":"Eʋegbe"},
        {"code":"fo","name":"Faroese","nativeName":"føroyskt"},
        {"code":"fj","name":"Fijian","nativeName":"vosa Vakaviti"},
        {"code":"fi","name":"Finnish","nativeName":"suomi, suomen kieli"},
        {"code":"fr","name":"French","nativeName":"français, langue française"},
        {"code":"ff","name":"Fula; Fulah; Pulaar; Pular","nativeName":"Fulfulde, Pulaar, Pular"},
        {"code":"gl","name":"Galician","nativeName":"Galego"},
        {"code":"ka","name":"Georgian","nativeName":"ქართული"},
        {"code":"de","name":"German","nativeName":"Deutsch"},
        {"code":"el","name":"Greek, Modern","nativeName":"Ελληνικά"},
        {"code":"gn","name":"Guaraní","nativeName":"Avañeẽ"},
        {"code":"gu","name":"Gujarati","nativeName":"ગુજરાતી"},
        {"code":"ht","name":"Haitian; Haitian Creole","nativeName":"Kreyòl ayisyen"},
        {"code":"ha","name":"Hausa","nativeName":"Hausa, هَوُسَ"},
        {"code":"he","name":"Hebrew (modern)","nativeName":"עברית"},
        {"code":"hz","name":"Herero","nativeName":"Otjiherero"},
        {"code":"hi","name":"Hindi","nativeName":"हिन्दी, हिंदी"},
        {"code":"ho","name":"Hiri Motu","nativeName":"Hiri Motu"},
        {"code":"hu","name":"Hungarian","nativeName":"Magyar"},
        {"code":"ia","name":"Interlingua","nativeName":"Interlingua"},
        {"code":"id","name":"Indonesian","nativeName":"Bahasa Indonesia"},
        {"code":"ie","name":"Interlingue","nativeName":"Originally called Occidental; then Interlingue after WWII"},
        {"code":"ga","name":"Irish","nativeName":"Gaeilge"},
        {"code":"ig","name":"Igbo","nativeName":"Asụsụ Igbo"},
        {"code":"ik","name":"Inupiaq","nativeName":"Iñupiaq, Iñupiatun"},
        {"code":"io","name":"Ido","nativeName":"Ido"},
        {"code":"is","name":"Icelandic","nativeName":"Íslenska"},
        {"code":"it","name":"Italian","nativeName":"Italiano"},
        {"code":"iu","name":"Inuktitut","nativeName":"ᐃᓄᒃᑎᑐᑦ"},
        {"code":"ja","name":"Japanese","nativeName":"日本語 (にほんご／にっぽんご)"},
        {"code":"jv","name":"Javanese","nativeName":"basa Jawa"},
        {"code":"kl","name":"Kalaallisut, Greenlandic","nativeName":"kalaallisut, kalaallit oqaasii"},
        {"code":"kn","name":"Kannada","nativeName":"ಕನ್ನಡ"},
        {"code":"kr","name":"Kanuri","nativeName":"Kanuri"},
        {"code":"ks","name":"Kashmiri","nativeName":"कश्मीरी, كشميري‎"},
        {"code":"kk","name":"Kazakh","nativeName":"Қазақ тілі"},
        {"code":"km","name":"Khmer","nativeName":"ភាសាខ្មែរ"},
        {"code":"ki","name":"Kikuyu, Gikuyu","nativeName":"Gĩkũyũ"},
        {"code":"rw","name":"Kinyarwanda","nativeName":"Ikinyarwanda"},
        {"code":"ky","name":"Kirghiz, Kyrgyz","nativeName":"кыргыз тили"},
        {"code":"kv","name":"Komi","nativeName":"коми кыв"},
        {"code":"kg","name":"Kongo","nativeName":"KiKongo"},
        {"code":"ko","name":"Korean","nativeName":"한국어 (韓國語), 조선말 (朝鮮語)"},
        {"code":"ku","name":"Kurdish","nativeName":"Kurdî, كوردی‎"},
        {"code":"kj","name":"Kwanyama, Kuanyama","nativeName":"Kuanyama"},
        {"code":"la","name":"Latin","nativeName":"latine, lingua latina"},
        {"code":"lb","name":"Luxembourgish, Letzeburgesch","nativeName":"Lëtzebuergesch"},
        {"code":"lg","name":"Luganda","nativeName":"Luganda"},
        {"code":"li","name":"Limburgish, Limburgan, Limburger","nativeName":"Limburgs"},
        {"code":"ln","name":"Lingala","nativeName":"Lingála"},
        {"code":"lo","name":"Lao","nativeName":"ພາສາລາວ"},
        {"code":"lt","name":"Lithuanian","nativeName":"lietuvių kalba"},
        {"code":"lu","name":"Luba-Katanga","nativeName":""},
        {"code":"lv","name":"Latvian","nativeName":"latviešu valoda"},
        {"code":"gv","name":"Manx","nativeName":"Gaelg, Gailck"},
        {"code":"mk","name":"Macedonian","nativeName":"македонски јазик"},
        {"code":"mg","name":"Malagasy","nativeName":"Malagasy fiteny"},
        {"code":"ms","name":"Malay","nativeName":"bahasa Melayu, بهاس ملايو‎"},
        {"code":"ml","name":"Malayalam","nativeName":"മലയാളം"},
        {"code":"mt","name":"Maltese","nativeName":"Malti"},
        {"code":"mi","name":"Māori","nativeName":"te reo Māori"},
        {"code":"mr","name":"Marathi (Marāṭhī)","nativeName":"मराठी"},
        {"code":"mh","name":"Marshallese","nativeName":"Kajin M̧ajeļ"},
        {"code":"mn","name":"Mongolian","nativeName":"монгол"},
        {"code":"na","name":"Nauru","nativeName":"Ekakairũ Naoero"},
        {"code":"nv","name":"Navajo, Navaho","nativeName":"Diné bizaad, Dinékʼehǰí"},
        {"code":"nb","name":"Norwegian Bokmål","nativeName":"Norsk bokmål"},
        {"code":"nd","name":"North Ndebele","nativeName":"isiNdebele"},
        {"code":"ne","name":"Nepali","nativeName":"नेपाली"},
        {"code":"ng","name":"Ndonga","nativeName":"Owambo"},
        {"code":"nn","name":"Norwegian Nynorsk","nativeName":"Norsk nynorsk"},
        {"code":"no","name":"Norwegian","nativeName":"Norsk"},
        {"code":"ii","name":"Nuosu","nativeName":"ꆈꌠ꒿ Nuosuhxop"},
        {"code":"nr","name":"South Ndebele","nativeName":"isiNdebele"},
        {"code":"oc","name":"Occitan","nativeName":"Occitan"},
        {"code":"oj","name":"Ojibwe, Ojibwa","nativeName":"ᐊᓂᔑᓈᐯᒧᐎᓐ"},
        {"code":"cu","name":"Old Church Slavonic, Church Slavic, Church Slavonic, Old Bulgarian, Old Slavonic","nativeName":"ѩзыкъ словѣньскъ"},
        {"code":"om","name":"Oromo","nativeName":"Afaan Oromoo"},
        {"code":"or","name":"Oriya","nativeName":"ଓଡ଼ିଆ"},
        {"code":"os","name":"Ossetian, Ossetic","nativeName":"ирон æвзаг"},
        {"code":"pa","name":"Panjabi, Punjabi","nativeName":"ਪੰਜਾਬੀ, پنجابی‎"},
        {"code":"pi","name":"Pāli","nativeName":"पाऴि"},
        {"code":"fa","name":"Persian","nativeName":"فارسی"},
        {"code":"pl","name":"Polish","nativeName":"polski"},
        {"code":"ps","name":"Pashto, Pushto","nativeName":"پښتو"},
        {"code":"pt","name":"Portuguese","nativeName":"Português"},
        {"code":"qu","name":"Quechua","nativeName":"Runa Simi, Kichwa"},
        {"code":"rm","name":"Romansh","nativeName":"rumantsch grischun"},
        {"code":"rn","name":"Kirundi","nativeName":"kiRundi"},
        {"code":"ro","name":"Romanian, Moldavian, Moldovan","nativeName":"română"},
        {"code":"ru","name":"Russian","nativeName":"русский язык"},
        {"code":"sa","name":"Sanskrit (Saṁskṛta)","nativeName":"संस्कृतम्"},
        {"code":"sc","name":"Sardinian","nativeName":"sardu"},
        {"code":"sd","name":"Sindhi","nativeName":"सिन्धी, سنڌي، سندھی‎"},
        {"code":"se","name":"Northern Sami","nativeName":"Davvisámegiella"},
        {"code":"sm","name":"Samoan","nativeName":"gagana faa Samoa"},
        {"code":"sg","name":"Sango","nativeName":"yângâ tî sängö"},
        {"code":"sr","name":"Serbian","nativeName":"српски језик"},
        {"code":"gd","name":"Scottish Gaelic; Gaelic","nativeName":"Gàidhlig"},
        {"code":"sn","name":"Shona","nativeName":"chiShona"},
        {"code":"si","name":"Sinhala, Sinhalese","nativeName":"සිංහල"},
        {"code":"sk","name":"Slovak","nativeName":"slovenčina"},
        {"code":"sl","name":"Slovene","nativeName":"slovenščina"},
        {"code":"so","name":"Somali","nativeName":"Soomaaliga, af Soomaali"},
        {"code":"st","name":"Southern Sotho","nativeName":"Sesotho"},
        {"code":"es","name":"Spanish; Castilian","nativeName":"español, castellano"},
        {"code":"su","name":"Sundanese","nativeName":"Basa Sunda"},
        {"code":"sw","name":"Swahili","nativeName":"Kiswahili"},
        {"code":"ss","name":"Swati","nativeName":"SiSwati"},
        {"code":"sv","name":"Swedish","nativeName":"svenska"},
        {"code":"ta","name":"Tamil","nativeName":"தமிழ்"},
        {"code":"te","name":"Telugu","nativeName":"తెలుగు"},
        {"code":"tg","name":"Tajik","nativeName":"тоҷикӣ, toğikī, تاجیکی‎"},
        {"code":"th","name":"Thai","nativeName":"ไทย"},
        {"code":"ti","name":"Tigrinya","nativeName":"ትግርኛ"},
        {"code":"bo","name":"Tibetan Standard, Tibetan, Central","nativeName":"བོད་ཡིག"},
        {"code":"tk","name":"Turkmen","nativeName":"Türkmen, Түркмен"},
        {"code":"tl","name":"Tagalog","nativeName":"Wikang Tagalog, ᜏᜒᜃᜅ᜔ ᜆᜄᜎᜓᜄ᜔"},
        {"code":"tn","name":"Tswana","nativeName":"Setswana"},
        {"code":"to","name":"Tonga (Tonga Islands)","nativeName":"faka Tonga"},
        {"code":"tr","name":"Turkish","nativeName":"Türkçe"},
        {"code":"ts","name":"Tsonga","nativeName":"Xitsonga"},
        {"code":"tt","name":"Tatar","nativeName":"татарча, tatarça, تاتارچا‎"},
        {"code":"tw","name":"Twi","nativeName":"Twi"},
        {"code":"ty","name":"Tahitian","nativeName":"Reo Tahiti"},
        {"code":"ug","name":"Uighur, Uyghur","nativeName":"Uyƣurqə, ئۇيغۇرچە‎"},
        {"code":"uk","name":"Ukrainian","nativeName":"українська"},
        {"code":"ur","name":"Urdu","nativeName":"اردو"},
        {"code":"uz","name":"Uzbek","nativeName":"zbek, Ўзбек, أۇزبېك‎"},
        {"code":"ve","name":"Venda","nativeName":"Tshivenḓa"},
        {"code":"vi","name":"Vietnamese","nativeName":"Tiếng Việt"},
        {"code":"vo","name":"Volapük","nativeName":"Volapük"},
        {"code":"wa","name":"Walloon","nativeName":"Walon"},
        {"code":"cy","name":"Welsh","nativeName":"Cymraeg"},
        {"code":"wo","name":"Wolof","nativeName":"Wollof"},
        {"code":"fy","name":"Western Frisian","nativeName":"Frysk"},
        {"code":"xh","name":"Xhosa","nativeName":"isiXhosa"},
        {"code":"yi","name":"Yiddish","nativeName":"ייִדיש"},
        {"code":"yo","name":"Yoruba","nativeName":"Yorùbá"},
        {"code":"za","name":"Zhuang, Chuang","nativeName":"Saɯ cueŋƅ, Saw cuengh"}]
    '''
    lang_list = [{"code":"ja","name":"Japanese","nativeName":"日本語 (にほんご／にっぽんご)"},
                 {"code":"en","name":"English","nativeName":"English"},]
    list_translatedvenuenames = []
    searchParams = []
    list_fromfsq = []

    for lang_details in lang_list
      searchParams.push "/venues/#{@venueresult.id}?locale=" + lang_details["code"]
    $.ajax
      url: "https://api.foursquare.com/v2/multi"
      datatype: "json"
      data:
        requests: searchParams.join ","
        m: "swarm"
        v: "20190101"
        oauth_token: token
      success: (data) =>
        googUrl = "https://translation.googleapis.com/language/translate/v2/detect?key=AIzaSyCKnwhjRWjBv3CVOOg2IbjvIO4t9720EuY"
        for response, i in data.response.responses
          googUrl = googUrl + "&q=" + response.response.venue.name.slice
          list_fromfsq.push(response.response.venue.name)
        $.ajax
          url: googUrl
          datatype: "json"
          success: (googData) =>
            for goog_response, goog_i in googData.data.detections
              console.log goog_response[0].language
              console.log lang_list[goog_i]["code"]
              if goog_response.language == lang_list[goog_i]["code"]
                list_translatedvenuenames.push {"lang": lang_list[goog_i]["code"], "name": list_fromfsq[goog_i]}
                HandlebarsTemplates['venues/edit_venue_details/_translatedvenuenames']
                  list_tvn: list_translatedvenuenames

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
      @setupTranslatedVenueNamesEditor(popover)

    .on "hidden", (e) ->
      attach.removeClass('active')
      $(e.target).removeClass("open-popover")

window.DetailsEditor = DetailsEditor
