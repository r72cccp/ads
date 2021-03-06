#--------------------------------------------------------------------------------------------------
$(document).click (e)->
	document_onclick e

#--------------------------------------------------------------------------------------------------
$(document).ready ->
	window.doc_ready()

#--------------------------------------------------------------------------------------------------
$(window).resize ->
	window.doc_ready()

#--------------------------------------------------------------------------------------------------
window.onresize = ->
	if get_right("#to_home") > $("#content").position().left
		$("#content").css
			"margin-top": "70px"
	else
		$("#content").css
			"margin-top": "0px"

#--------------------------------------------------------------------------------------------------
window.doc_ready = ->
	window_size = window.getWindowSize()
	$("#content").css
		height: "#{window_size.height-parseInt($('#content').css('margin-top'))-30}px"
	$("#ads_index_mini").css
		height: "#{window_size.height-100}px"
	$("#ads_index_mini").scroll ->
		infinite_ajax_scroll(this)
	$("#content").scroll ->
		if $("#content .ad_list").length > 0
			infinite_ajax_scroll(this)
	convert_data_datetime()

#--------------------------------------------------------------------------------------------------
infinite_ajax_scroll = (elem) ->
	not_answered_request_timestamp = window.localStorage.getItem("not_maintained_request")
	if scrolled_to_bottom_percent(elem) > window.limit_1 && !not_answered_request_timestamp
		last_ads_timestamp = Date.parse( $(".ads_list > .ad_item:last-of-type .ad_created_at p").attr("data-datetime") )
		so_oldiest_we_never_wanted = !not_answered_request_timestamp || not_answered_request_timestamp && last_ads_timestamp && parseInt(not_answered_request_timestamp) <= parseInt(last_ads_timestamp)
		if so_oldiest_we_never_wanted
			window.get_ajax "/", 
				layout: false
				timezone: window.timezone_name()
				older_than: last_ads_timestamp
				count: window.limit_2
			, true, "GET", window.update_index, 
				layout: false
				position: "append"
			, "json"
			window.localStorage.setItem("not_maintained_request", last_ads_timestamp)

#-- we use cached index in all cases, if already downloaded some ads from server - this save it to window.localStorage -
window.store_index = ->
	index_content1 = $("#ads_index_mini .ads_list").parent().html() || ""
	index_content2 = $("#content > .ads_list").parent().html() || ""
	index_content = if index_content1.length > index_content2.length then index_content1 else index_content2
	cache = window.localStorage.getItem("ads_list")
	if index_content && cache && index_content.length > cache.length || index_content
		window.localStorage.setItem("ads_list", index_content)

#--------------------------------------------------------------------------------------------------
window.restore_index = ->
	stored_index_content = window.localStorage.getItem("ads_list")
	ads_list_content = $(".ads_list").html()
	if !ads_list_content && stored_index_content || ads_list_content && ads_list_content.length > 0 && stored_index_content && ads_list_content.length < stored_index_content.length
		$(".ads_list").html(stored_index_content.replace(/^[\s\S]+"ads_list">/,'').replace(/<\/div>$/,''))

#-- we recieve all ads with server time in attribute data-datetime. So, it ca convert all dates to locale timezone and format -
convert_data_datetime = ->
	for p in $("[data-datetime]")
		d = new Date(p.getAttribute("data-datetime"))
		$(p).html(d)

#-- if we receive new portion of ads from server, index must be updated by some params and received html -
window.update_index = (data, params) ->
	params["no_scroll"] = "true"
	window.draw_index data, params
	window.localStorage.removeItem("not_maintained_request")

#--------------------------------------------------------------------------------------------------
window.draw_index = (response, params) ->
	if params
		fn = params["position"]
	if $("#ads_index_mini").length > 0
		if $($("#ads_index_mini .ads_list")).length > 0
			if fn
				$(".ads_list")[fn]($(response).children())
			else
				if $(".ads_list").html().length < response.length
					$(".ads_list").replaceWith($(response))
					$("#ads_index_mini h1").remove()
		else
			$("#ads_index_mini").html(response)
			$("#ads_index_mini h1").remove()
	if $("#content > .ads_list").length > 0
		if fn
			$("#content > .ads_list")[fn]($(response).children())
	convert_data_datetime()
	current_index = 0
	for ad_item, index in $(".ad_item")
		if $(ad_item).children("a")[0].getAttribute("href") != window.location.pathname
			$(ad_item).removeClass("current")
		else
			item = $(ad_item)
			item.addClass("current")
			if !params || !params["no_scroll"]
				current_scroll = $("#ads_index_mini").scrollTop()
				index_height = $("#ads_index_mini").height()
				item_position = item.position().top
				item_height = item.height()
				if item_position + item_height > index_height || item_position < 0
					$("#ads_index_mini").scrollTop(item_position + current_scroll)

#--------------------------------------------------------------------------------------------------
scrolled_to_bottom_percent = (o) ->
	$(o).scrollTop() / (o.scrollHeight - $(o).height())

#--------------------------------------------------------------------------------------------------
ad_content = (ad) ->
	HandlebarsTemplates['ad_item']({ad: ad})

#--------------------------------------------------------------------------------------------------
init_new_ads = ->
	HandlebarsTemplates['new_ad']({id: makeid(7)})

#--------------------------------------------------------------------------------------------------
document_onclick = (e) ->
	if /new_ad/.test e.target.id
		content = window.localStorage.getItem("new_ads_editor")
		if !content || content.length == 0
			content = init_new_ads()
		$.fancybox
			content: content
			padding: 0
			width: 848
			height: 686
			scrolling: 'no'
			tpl:
				closeBtn: "<span class=\"close_map\"></span>"
			helpers:
				overlay:
					locked: true
					speedOut: 30
					css:
						'background-color': 'rgba(111,111,111,0.6)'
			beforeClose: ->
				$("textarea.ad_text").html($("textarea.ad_text").val())
				window.localStorage.setItem("new_ads_editor", $(".fancybox-inner").html())
		set_file_listener()
	else if /input_file/.test e.target.id
		$("input.file").click()
	else if /delete_img/.test e.target.getAttribute("data-type")
		$(e.target.parentNode).remove()
	else if /comment_img/.test e.target.getAttribute("data-type")
		comment_text = $(e.target).html()
		id = e.target.parentNode.id
		p_width = $(e.target).css("width")
		textarea = $(e.target).replaceWith("<textarea style='width: #{p_width}' id='#{id}' type='text' class='thumb-caption form-control'>#{comment_text}</textarea>")
		$("textarea##{id}").focus()
	else if /confirm/.test e.target.id
		ad_text = $("textarea.ad_text").val() 
		if ad_text == ""
			window.status_body "error", HandlebarsTemplates['text_needed_here']()
		else
			ads_images = []
			for img in $(".img_thumb")
				image = $(img)
				progressbar = image.parent().children("progress.upload-progress")
				ads_images.push
					id: $(".new_ads")[0].id #img.id
					filename: image.children("img").attr("data-filename")
					comment: image.children("p[data-type='comment_img']").html()
					uploaded: parseInt(progressbar.attr("value")) / parseInt(progressbar.attr("max"))
			window.get_ajax "/add_ads", 
				ads_text: ad_text
				ads_images: ads_images
			, true, "POST", render_new_ads
			$.fancybox.close()
			window.status_body "success", HandlebarsTemplates['ads_posted']()
			window.localStorage.removeItem("new_ads_editor")
	else if /cancel/.test e.target.id
		$.fancybox.close()

#--------------------------------------------------------------------------------------------------
$(document).mousedown (e) ->
	for textarea in $(".thumb-caption")
		if /thumb-caption/.test("#{textarea.className}") && textarea.id != e.target.id
			p_width = $(textarea).parent().children("img").css("width")
			new_text = $(textarea).val()
			$(textarea).replaceWith "<p style='width: #{p_width}' data-type='comment_img' class='img_comment'>#{new_text}</p>"

#--------------------------------------------------------------------------------------------------
render_new_ads = (data) ->
	window.customize_layout()

#--------------------------------------------------------------------------------------------------
set_file_listener = ->
	$(".file").change (event) ->
		input = $(event.currentTarget)
		readers = []
		for file in input[0].files
			file_id = makeid(7)
			fast_preview = HandlebarsTemplates['img_thumb']({src: "/assets/images/thumb_dumb.gif", img_comment: file.name, id: file_id})
			$(".upload-preview").append(fast_preview)
			$(".upload-preview").hide().show(0)
			o = new FileReader()
			o.file_id = file_id
			o.file = file
			o.readAsDataURL file
			o.onload = (e) ->
				image_base64 = e.target.result
				preview = HandlebarsTemplates['img_thumb']({src: image_base64, img_comment: @file.name, id: @file_id})
				pic_real_width = undefined
				pic_scaled_width = undefined
				pic_real_height = undefined
				pic_scaled_height = 100
				preloaded_image = $("<img id='#{@file_id}'/>")
				preloaded_image.file_id = @file_id
				preloaded_image.load( ->
					preloaded_image_id = $(this)[0].id
					$("##{preloaded_image_id}").replaceWith(preview)
					pic_real_width = @width
					pic_real_height = @height
					pic_scaled_width = pic_real_width * (100 / pic_real_height)
					$("##{preloaded_image_id}").css
						width: pic_scaled_width
					return
				).attr("src", image_base64)
				upload @file, onUploadSuccess, onUploadError, onUploadProgress, @file_id

#--------------------------------------------------------------------------------------------------
onUploadSuccess = (e, bar_id) ->
	$("##{bar_id} progress").css
		opacity: 0;
	ads_id = $('.new_ads').attr('id')
	ads_images_folder = ads_id.substring(bar_id.length-2,bar_id.length).toLowerCase()
	img_filename = $("##{bar_id} img").attr('data-filename')
	$("##{bar_id} img").attr
		src: "/system/uploads/#{ads_images_folder}/#{img_filename}"

#-- upload error listener -------------------------------------------------------------------------
onUploadError = (e) ->
	console.log "error"
	console.log e

#-- draw progressbar on uploaded image preview ----------------------------------------------------
onUploadProgress = (loaded, total, bar_id) ->
	$("##{bar_id} progress").attr("value", "#{loaded / total * 100}")

#-- Upload one file to host ---------------------------------------------------------------------
upload = (file, onUploadSuccess, onUploadError, onUploadProgress, bar_id) ->
	xhr = new XMLHttpRequest()
	xhr.onload = xhr.onerror = ->
		if @status isnt 200
			onUploadError this
			return
		onUploadSuccess(this, bar_id)
		return

	xhr.upload.onprogress = (event) ->
		onUploadProgress event.loaded, event.total, bar_id
		return

	xhr.open "POST", "/upload_image?file_name=#{file.name}&ads_id=#{$('.new_ads').attr('id')}", true
	xhr.setRequestHeader('X-CSRF-Token', window.get_token())
	xhr.send file

#-- cancel all dragstart events -------------------------------------------------------------------
document.addEventListener "dragstart", ((e) ->
	e.preventDefault()
	return false
), false

#-- make random id string -------------------------------------------------------------------------
makeid = (length_of) ->
	text = ""
	possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	i = 0
	while i < length_of
		text += possible.charAt(Math.floor(Math.random() * possible.length))
		i++
	text

#-- pause animation in status message block if mouse hover on them ---------------------------------
$("div[id$='_wrapper']").hover (e)->

	state = '-webkit-animation-play-state'
	@.css state, (i, v) ->
		(if v is "paused" then "running" else "paused")
	@.toggleClass "paused", @.css(state) is "paused"

#-- close a success, error message by click ---------------------------------------------------------------------------
$(document).click (e)->
	id = window.get_attr(e.target, "id", 3)
	if /_wrapper/.test(id)
		$("[id$='_wrapper'] > div.data-transparent").css
			opacity: 0
		$("[id$='_wrapper']").css
			top: "-200px"

#- return horizontal coord of right side of element -----------------------------------------------
get_right = (elem) ->
	$(elem).position().left+$(elem).width()

