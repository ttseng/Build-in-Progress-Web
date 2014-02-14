jQuery(function() {

  // DESIGN FILE STUFF

  // add a design file field to the form  
  $('form').on('click', '.add_fields', function(event) {
    console.log('clicked add fields');
    time = new Date().getTime();
    regexp = new RegExp($(this).data('id'), 'g');
    $(this).parent().before($(this).data('fields').replace(regexp, time));
    $(this).find('.destroy_design_file').val('1');
    addRemoveLinks();
  });

   $('form').on('click', '.remove_fields', function(event){
    console.log('clicked remove_fields');
    $(this).addClass('file_to_remove');
    // remove newly upploaded files
    if($(this).parents('.design_file_upload_fieldset').length>0){
      $(this).prev('input[type=hidden]').val('1');
      $(this).parents('.design_file_upload_fieldset').fadeOut('300');
    }
    event.preventDefault();
   });

});

  // remove a design file from the form
  function remove_design_file(){
    console.log('removing existing design file');
    $('.file_to_remove').parents('.design_file_row').fadeOut('300');
    event.preventDefault();
  }

  // show or hide remove file link for design files form
  function addRemoveLinks(){
    $('.design_file_upload_fieldset').each( function(){
      if( $(this).find('label').length > 0 ){
         $(this).find('.remove_fields').show();
       }else {
         $(this).find('.remove_fields').hide();
      }
    });
  }

  // add a new design file field to the form
  function addField(input) {
    var max_limit_for_file = 10000000; // do not allow files greater than 100MB
    if(input.files[0].size > max_limit_for_file){
      $(input).val('');
      alert("Your design file is greater than 10 MB and cannot be uploaded.")
    }else{    
      console.log('add design field input');
      // remove the filefield of recently uploaded file and replace with existing file styling
      var filename = $(input).val().split('\\').pop();  
      console.log(filename);
      $(input).parents('fieldset').prepend('<label>'+filename+'</label>');
      $(input).hide();
      $(input).parent().hide();
      $(input).parents('fieldset').find('.destroy_design_file').val('0');
      $('.add_fields').click();
    }
  }


 $(function(){  
     $('.best_in_place').best_in_place();
     $('.rest-in-place').restInPlace();
  });  

 // stop any vimeo players that are playing when the user switches items in the carousel
function stopVimeo(carousel){
   var iframes = carousel.find('iframe');        
    for(var i =0; i< iframes.length; i++){
      var is_vimeo_iframe = $(iframes[i]).attr('src').indexOf('vimeo')>=0;
      var is_active = $(iframes[i]).closest('.item').attr('class').indexOf('active') >=0;
      // only stop the video if it's not active
      if(is_vimeo_iframe && !is_active){
        $(iframes[i]).attr('src', $(iframes[i]).attr('src'));
      }
    }
}

// stop all soundcloud players in this carousel from playing
function stopSoundcloud(carousel){
  carousel.find('iframe').each(function(index,iframe){
    if (iframe.src.indexOf("soundcloud") >=0){
  //    console.log('stopping soundclouds');
      SC.Widget(iframe).pause();
    }
  });
}

// stop html players from playing
function stopHTMLVideo(carousel){
    carousel.find('video').each(function(index, video){
    //    console.log('video: ' +  video);
        video.pause();
    });
}

// reset video masks
function reset_video_masks(carousel){
    // resetting all masks
    var iframeID = carousel.find('iframe').attr("id");
    // stop iframe from playing
    if(iframeID != undefined){
      callPlayer(iframeID, 'stopVideo');
    }
    // turn on all masks
    carousel.find('.video_mask').show();
    // reset src of all videos
    $('.projectOverviewCarousel').find('iframe').each(function(key, value){
      url = $(this).attr('src');
      if(url.indexOf("autoplay")>0){
        new_url = url.substring(0, url.indexOf("?"));
        $(this).attr('src', new_url);
      }
    });
}

// check valid type of direct uploaded files (for now just images)
function check_valid_filetype(file){
  console.log('checking valid filetype');
  console.log(file.size);

    regex = /(\.|\/)(gif|jpe?g|png)$/i;
    if (regex.test(file.name) == false){
          alert('Please select a valid image type (jpeg, png, or gif).');
          return false;
    }
    else if (file.size > 5000000 ) {
        alert('Your file is too large! Please select a file that is less than 5MB.');
       return false;
    }
    else {
       return true;
    }
  }

// close any youtube players that are playing when the user switches items in the carousel
  function callPlayer(frame_id, func, args) {
  	// console.log('attempting to close youtube players');
    if (window.jQuery && frame_id instanceof jQuery) frame_id = frame_id.get(0).id;
    var iframe;
    if(frame_id){
      var iframe = document.getElementById(frame_id);
    }
    if (iframe && iframe.tagName.toUpperCase() != 'IFRAME') {
        iframe = iframe.getElementsByTagName('iframe')[0];
    }

    // When the player is not ready yet, add the event to a queue
    // Each frame_id is associated with an own queue.
    // Each queue has three possible states:
    //  undefined = uninitialised / array = queue / 0 = ready
    if (!callPlayer.queue) callPlayer.queue = {};
    var queue = callPlayer.queue[frame_id],
        domReady = document.readyState == 'complete';

    if (domReady && !iframe) {
        // DOM is ready and iframe does not exist. Log a message
        window.console && console.log('callPlayer: Frame not found; id=' + frame_id);
        if (queue) clearInterval(queue.poller);
    } else if (func === 'listening') {
        // Sending the "listener" message to the frame, to request status updates
        if (iframe && iframe.contentWindow) {
            func = '{"event":"listening","id":' + JSON.stringify(''+frame_id) + '}';
            iframe.contentWindow.postMessage(func, '*');
        }
    } else if (!domReady || iframe && (!iframe.contentWindow || queue && !queue.ready)) {
        if (!queue) queue = callPlayer.queue[frame_id] = [];
        queue.push([func, args]);
        if (!('poller' in queue)) {
            // keep polling until the document and frame is ready
            queue.poller = setInterval(function() {
                callPlayer(frame_id, 'listening');
            }, 250);
            // Add a global "message" event listener, to catch status updates:
            messageEvent(1, function runOnceReady(e) {
                var tmp = JSON.parse(e.data);
                if (tmp && tmp.id == frame_id && tmp.event == 'onReady') {
                    // YT Player says that they're ready, so mark the player as ready
                    clearInterval(queue.poller);
                    queue.ready = true;
                    messageEvent(0, runOnceReady);
                    // .. and release the queue:
                    while (tmp = queue.shift()) {
                        callPlayer(frame_id, tmp[0], tmp[1]);
                    }
                }
            }, false);
        }
    } else if (iframe && iframe.contentWindow) {
        // When a function is supplied, just call it (like "onYouTubePlayerReady")
        if (func.call) return func();
        // Frame exists, send message
        iframe.contentWindow.postMessage(JSON.stringify({
            "event": "command",
            "func": func,
            "args": args || [],
            "id": frame_id
        }), "*");
    }
    /* IE8 does not support addEventListener... */
    function messageEvent(add, listener) {
        var w3 = add ? window.addEventListener : window.removeEventListener;
        w3 ?
            w3('message', listener, !1)
        :
            (add ? window.attachEvent : window.detachEvent)('onmessage', listener);
    }
  }

  function loadCarousels(source){
    if(source=="index"){
      // enable pointer cursor when user hovers over thumbnail gallery images
      $('.thumbGallery').addClass('view');

      // change cursor to pointer if hovering over thumbnails
      $('.thumbGallery img').hover(function(){
        $(this).css("cursor", "pointer");
      }, function(){
        $(this).css("cursor", "default");
      });

      // set photo active in carousel when thumbnail is clicked
      $('.thumbGallery .image').click(function(){
          var child_image = $(this).find('img')
          var carouselID = child_image.attr("data-parent");
          var image = parseInt(child_image.attr("data-position"));

          // slide to the element in the slideshow
           $('.carousel.'+carouselID).carousel(image);

      });      
  }

    // initiate fancybox lightbox plugin
    $(".fancybox").fancybox({
      helpers: {
        overlay: {
          locked: false
        }
      },
      afterLoad: function(current, previous){
        // pause the project overview carousel
        $('.projectOverviewCarousel').carousel('pause');
      },
      afterClose: function(){
        // restart project overview carousel
        $('.projectOverviewCarousel').carousel('cycle');
      }
    });


    // start carousel
    $('.carousel.slide').carousel({
        interval: false
    });

    // reveal navigaton if there is more than one image in the carousel
    $('.mainPhoto').hover(function(){
      var number_images = $(this).children('.carousel-inner').children('.item').length

        if(number_images>1){
          // reveal navigation
          // $(this).children('a').fadeIn("fast");
          }
      },
      function(){
        // hide navigation
        // $(this).children('a').fadeOut("fast");
    });

  }

    // go to image in carousel
  function setCarousel(carouselID, image){
    if($('.item.active').length>0){
      // reset the existing active item
      $('.carousel.'+carouselID+' .item.active').removeClass('active');
    }
      $('.carousel.'+carouselID + ' div:nth-child('+image+')').addClass('active');  
    }


  /* carousel_video_iframe -  return embed code for video iframe (from youtube or vimeo)
     video_source = embed url for the youtube / vimeo video
     step_id = id of the step the video belongs to
     image_id = id of the image associated with the video
     active = whether or not the image is the first one in the carousel
  */

  function carousel_video_iframe(video_source, step_id, image_id, active){
      return '<div class="item embed_video ' + active +'"><div class="flex-video"><a class="fancybox" href="'+video_source+' rel="gallery ' + step_id + '" data-fancybox-type="iframe"><iframe src="'+ video_source + '" class="' + image_id + '" id="video_' + image_id + '"></iframe></a></div></div>'
  }

   /* carousel_video_player - return code to embed html 5 player for uploaded videos
     video_source = url of the video (from amazon s3)
     step_id = id of the step the video belongs to
     image_id = id of the image associated with the video
     active = whether or not the image is the first one in the carousel
  */

  function carousel_video_player(video_source_mp4, video_source_webm, step_id, image_id, active){
      return '<div class="item s3_video ' + active + '"><div class="flex-video uploaded-video"><a class="fancybox" href="'+video_source_webm +'" rel="gallery ' + step_id + '" data-fancybox-type="iframe"></a><video controls><source src="'+ video_source_webm + '" class="' + image_id + '" id="video_' + image_id + '" type="video/webm"><source src="'+ video_source_mp4 + '" class="' + image_id + '" id="video_' + image_id + '" type="video/mp4"></video></div></div>'
  }

   /* carousel_soundcloud_iframe - return code to embed soundcloud player
     souncloud_source = embed url for the soundcloud file
     step_id = id of the step the video belongs to
     image_id = id of the image associated with the sound
     active = whether or not the image is the first one in the carousel
  */

  function carousel_soundcloud_iframe(sound_source, step_id, image_id, active){
      return '<div class="item sound '+active+'"><div class="soundcloud"><a class="fancybox" href="'+sound_source+'" rel="gallery ' + step_id + '" data-fancybox-type="iframe"><iframe src="'+ sound_source + '&amp;show_comments=true&amp;show_artwork=false" class="' + image_id + '" id="sound_' + image_id + '"></iframe></a></div></div>'
  }

  /* trigger_video_mask - when user clicks on mask, stop slideshow and play media
  */
  function trigger_video_mask(mask){
      // start playing video automatically
    iframe = mask.closest('.item').find('iframe');
    if (iframe.length!=0){
      iframe_source = iframe.attr('src');
      if(iframe_source.indexOf('youtube')>=0){
        iframe_source = iframe_source + "?autoplay=1"
        iframe.attr('src', iframe_source);
      }else if(iframe_source.indexOf('soundcloud')>=0){
        iframe_source = iframe_source + "&auto_play=true"
        iframe.attr('src', iframe_source);
      }
    }else{
      video = mask.closest('.item').find('video')
      video.get(0).play();
    }    
    
      // hide the mask
      mask.toggle();
    
      // stop the slideshow
      if(mask.closest('.projectOverviewCarousel').length>0){
        $('.projectOverviewCarousel').carousel('pause');  
        // switch slideshow icon
        $('.play_pause').removeClass('fa fa-pause');
        $('.play_pause').addClass('fa fa-play');
      }else{
        console.log('stopping carousel');
        mask.closest('.carousel').carousel('pause');
      }
    }


  /* carousel_caption - returns caption for remixed images to place in carousel
     image_id = the id # of the image in the carousel
     project_overview = boolean to store whether or not we're from the project overview carousel
     original_project_path = link to the original project
     original_project_title = title of the original project
     user_profile_path = link to the user profile
     original_user = the author's name
  */
  function remix_caption(image_id, project_overview, original_project_path, original_project_title, user_profile_path, original_user){
    if(project_overview){
      var media_object = $('.projectOverviewCarousel .'+image_id);
    }else{
      var media_object = $('.carousel').not('projectOverviewCarousel').find('.'+image_id);  
    }
    
    var media_object_item = media_object.closest('.item');

    // add caption to carousel
       media_object_item.append('<div class="carousel-caption">from <a href ="'+original_project_path+'">'+original_project_title+'</a> by <a href="'+user_profile_path+'">'+original_user+'</a></div>');
    // adjust the size of videos to enable controls to be used with caption
    if(media_object_item.hasClass('embed_video')){
      media_object_item.find('iframe').css('height', '95%');
    }else if(media_object_item.hasClass('s3_video')){
        media_object.closest('.item').find('video').css('height', '95%');
    }   

    // add caption to fancybox
    if(media_object.first().closest('.item').hasClass('s3_video')){
        media_object.first().closest('.flex-video').children('a').attr("title", 'from <a href ="'+original_project_path+'">'+original_project_title+'</a> by <a href="'+user_profile_path+'">'+original_user+'</a></div>');
    }else{
        media_object.closest('a').attr("title", 'from <a href ="'+original_project_path+'">'+original_project_title+'</a> by <a href="'+user_profile_path+'">'+original_user+'</a></div>');
    }
  }

  // remove image from the step form (both from the carousel and the thumbnail gallery)
  // item = $('.image') thumbnail item (corresponding to image whose trash icon was clicked)
  function destroy_saved_image(item){
    var step_carousel = $('.mainPhoto:not(.projectOverviewCarousel)');
    
    // get carousel image and remove
    if(item.attr('id')!=undefined){
      // user is editing an image that has already been saved to the DB
      var imageID = getImageID(item.attr('id'));
      console.log("imageID: " + imageID);
      var carouselItem = step_carousel.find('.'+imageID).closest('.item');
      var carouselIndex = step_carousel.find('.item').index(carouselItem);
      carouselItem.remove();
    }else{
      // user is editing an image that was just uploaded
      var image_src = item.find('img').attr('src');
      var carouselItem = step_carousel.find('img[src="'+image_src+'"]').closest('.item');
      var carouselIndex = step_carousel.find('.item').index(carouselItem);
      carouselItem.remove();
    }

    // remove image from thumbnail gallery
    item.fadeOut(1000);
    item.remove();
    
    if($('.image').length==0){
      $('#blankPhoto').fadeIn(500);
      addImageButton("left"); 
    }

    $('.carousel .active').removeClass('active');
      // if first image was removed, make the next image active, else make the last image active
    if(carouselIndex==0){
      $('.detailViewPhoto .item').first().addClass("active");
    }else{
      $('.detailViewPhoto .item').last().addClass("active");
    } 

    var stepImagesCount = $('.image').length;
    if(stepImagesCount==1){
      // hide the navigation if there's only one image
      $('.carousel .carousel-control').remove();
    }
    // reset the modal forms
      resetVideoModal();
      resetOtherMediaModal();
  }

  function getImageID(fullID){
    var start = fullID.indexOf('_')+1;
    return fullID.substring(start, fullID.length);
  }

  // highlight div for 1.5 seconds
  $.fn.animateHighlight = function(highlightColor, duration){
       var highlightBg = highlightColor || "#FFFF9C";
       var animateMs = duration || 1500;
       var originalBg = this.css("backgroundColor");
       this.stop().css("background-color", highlightBg).animate({backgroundColor: originalBg}, animateMs);
  }

  // finds the numerical ID for a class containing an identifier (for example, passing 
  // getClassID("step", "step_2") for an element with the class "step_2" will return 2)
  function getClassID(identifier, full_class){
    var start = full_class.indexOf('identifier')+identifier.length+2;
    var end = full_class.length;
    return full_class.substring(start, end);
    
  }
