//////////////////////////////////
//////////////////////////////////
///////  IMAGE FUNCTIONS   ///////
//////////////////////////////////
//////////////////////////////////

  var zoom; // this is used for determining the zoom level in the mobile application branching

      // function check_valid_filetype
      // check that the uploaded image is a valid filetype (jpeg, png, or gif)
      // file: the file being uploaded

      function check_valid_filetype(file){
        // console.log(file.size);

          regex = /(\.|\/)(gif|jpe?g|png)$/i;
          if (regex.test(file.name) == false){
                // alert('Please select a valid image type (jpeg, png, or gif).');
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

        // function lazyContainer
        // lazy load assets in carousels
        
        function lazyContainer(searchNode) {
          // lazy load images
           $(searchNode).find('img.lazy').each(function() {
             var imgSrc = $(this).attr('data-src');
             if (imgSrc) {
                $(this).hide();
                 $(this).attr('src',imgSrc);
                 $(this).attr('data-src','');
                 $(this).fadeIn();
             }
            });

           $(searchNode).find('video.lazy').each(function(){
            var sources = $(this).find('source');
            sources.each(function(){
              var videoSrc = $(this).attr('data-src');  
              // console.log(videoSrc);
              if(videoSrc){
                 $(this).hide();
                 $(this).attr('src', videoSrc);
                 $(this).attr('data-src', '');
                 $(this).parent().load();
                 $(this).fadeIn();
              }
            })
           })
          }

        // function destroy_saved_image(item)
        // remove image from the step form (both from the carousel and the thumbnail gallery)
        // item = $('.image') thumbnail item (corresponding to image whose trash icon was clicked)
        function destroy_saved_image(item){
          // console.log('in destroy saved image');
          var step_carousel = $('.mainPhoto:not(.projectOverviewCarousel)');
          
          // get carousel image and remove
          if(item.attr('id')!=undefined){
            // user is editing an image that has already been saved to the DB
            var imageID = getImageID(item.attr('id'));
            // console.log("imageID: " + imageID);
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

          if(carouselIndex==0){
            step_carousel.carousel(carouselIndex+1);
            step_carousel.find('.item').first().addClass('active');
          }else{
            step_carousel.carousel(carouselIndex-1);
            step_carousel.find('.item').last().addClass('active');
          } 
          
          if($('.image').length==0){
            $('#blankPhoto').fadeIn(500);
            addImageButton("left"); 
          }


          var stepImagesCount = $('.image').length;
          if(stepImagesCount==1){
            // hide the navigation if there's only one image
            $('.carousel .carousel-control').fadeOut();
          }
          // reset the modal forms
            resetVideoModal();
            resetOtherMediaModal();
        }

        // function getRotation(image)
        // get the current rotation value of an image object
        // image: jQuery image object
        function getRotation(image){

           // get current rotation of image
          var transform_matrix = image.css("-webkit-transform") || 
               image.css("-moz-transform") ||
               image.css("-ms-transform") ||
               image.css("-o-transform") ||
               image.css("transform");

          // console.log('transform matrix: ' + transform_matrix);              

          if(transform_matrix=="none" || typeof transform_matrix=='undefined'){
            return 0;
          }else{   
            var values = transform_matrix.split('(')[1];
                values = values.split(')')[0];
                values = values.split(',');
            var a = values[0];
            var b = values[1];
            var c = values[2];
            var d = values[3];

            var scale = Math.sqrt(a*a + b*b);
            var sin = b/scale;
            var angle = Math.round(Math.atan2(b, a) * (180/Math.PI));

            return angle;
          }
        }

        // function getFancyboxImageID()
        // get the id of the image to be loaded in the fancybox slideshow
        function getFancyboxImageID(){
          var src_url = $('.fancybox-image').attr('src');
          var src_url_2 = src_url.substring(src_url.indexOf('image_path')+"image_path".length+1, src_url.length);
          var id = src_url_2.substring(0, src_url_2.indexOf('/'));
          return id;
        }

        // function getFancyboxRotation()
        // get the rotation value of the image to be loaded in the fancybox slideshow
        // id: id of the image (integer)
        function getFancyboxRotation(id){
          var rotation = getRotation($($('#img_link_'+id).find('img')));
          return rotation;
        }

        // function fancyboxRotate()
        // rotate the image in the fancybox slideshow if it's been rotated on the step form
        // rotation: rotation value (integer)
        function fancyboxRotate(rotation){
          var rotation_string = 'rotate('+rotation+'deg)';
          console.log('rotating fancybox with rotation_string: ' + rotation_string);
          $('.fancybox-wrap').css('webkitTransform', rotation_string);
          $('.fancybox-wrap').css('-moz-transform', rotation_string);
        }

        // function applyImageRotation(carousel_img, thumbnail_img, rotation)
        // apply a given rotation value to both the carousel and thumbnail images (depending on whether we're on the index or edit page)
        // carousel_img: jQuery object for carousel image to be rotated
        // thumbnail_img: jQuery object of the thumbnail image to be rotated
        // rotation: rotation value (integer)
        // pageSource: whether we're coming from edit or index page
        function applyImageRotation(carousel_img, thumbnail_img, rotation, pageSource){
          // console.log(' ');
          // console.log('apply image rotation');
          if(pageSource=="edit" || pageSource=="new"){
            var carousel_width = '337px'; // width of image in carousel on edit page
          }else if(pageSource=="index"){
            var carousel_width = '381px'; // width of image in carousel on index page
          }
          
          var thumbnail_width = '99px'; // width of thumbnail image in thumbGallery
          var rotation_string = 'rotate('+rotation+'deg)';

          carousel_img.css('webkitTransform', rotation_string);
          carousel_img.css('-moz-transform', rotation_string);

          // set rotation for project overview carousel
          $('.projectOverviewCarousel img[src="' + carousel_img.attr('src') + '"]').css('webkitTransform', rotation_string);
          $('.projectOverviewCarousel img[src="' + carousel_img.attr('src') + '"]').css('-moz-transform', rotation_string);
          $('.projectOverviewCarousel img[src="' + carousel_img.attr('src') + '"]').css('height', $('.projectOverviewPhoto').width()+"px");

          thumbnail_img.css('webkitTransform', rotation_string);
          thumbnail_img.css('-moz-transform', rotation_string);

          if(rotation/90 %2 == 0){
            // 180, 360 degrees
            carousel_img.height('auto');
            carousel_img.removeClass('rotated_odd');
            carousel_img.addClass('rotated_even');        

            thumbnail_img.height('auto');
            thumbnail_img.removeClass('rotated_odd');
            thumbnail_img.addClass('rotated_even');
          }else{
            // 90, 270 degrees
            carousel_img.css('height', carousel_width);
            carousel_img.removeClass('rotated_even');
            carousel_img.addClass('rotated_odd');  
            
            if(pageSource == "edit" || pageSource == "new"){
              setCarouselImageMargins(carousel_img, carousel_width, undefined, undefined);
            }
            else if(pageSource=="index"){
              $('<img/>').on('load', function(){
                  // console.log($(this).attr('src'));
                  // console.log('carousel_img dimensions: ' + this.width + ' ' + this.height);
                  // calculate expanded dimensions
                  this.width = this.width * parseInt(carousel_width) / this.height;
                  this.height = parseInt(carousel_width); //width is actually height with rotated image
                  // console.log('final image and width: ' + this.width + ' ' + this.height);
                  setCarouselImageMargins(carousel_img, carousel_width, this.width, this.height);  
              }).attr('src', carousel_img[0].src);
            }
            
            thumbnail_img.css('height', thumbnail_width);
            thumbnail_img.removeClass('rotated_even');
            thumbnail_img.addClass('rotated_odd');

            if(pageSource=="edit" || pageSource=="new"){
              setThumbnailMargins(thumbnail_img, thumbnail_width);
            }else if(pageSource=="index"){
              thumbnail_img.on('load', function(){
                // console.log('applying thumbnail image margins');
                 setThumbnailMargins($(this), thumbnail_width);  
               });
            }
          }
        }

        // function setThumbnailMargins(image, width)
        // set the left margin for centering a thumbnail image in the thumbgallery after its been rotated
        // image: jQuery object of thumbnail image to be rotated
        // width: width of the image container (integer)
        function setThumbnailMargins(image, width){
          var image_width = image.width();
          var image_height = image.height();
          // console.log('setThumbnailMargins with thumbnail width: ' + image_width + " thumbnail height: " + image_height);
            if(image_width < image_height){
                thumbnail_left_margin = (image_height-parseInt(width))/2*-1;  
            }else{
              thumbnail_left_margin = (image_width-parseInt(width))/2*-1;  
            }             
            image.css('margin-left', thumbnail_left_margin);
            image.removeClass('temp-image-thumbnail'); // remove class that 'hides' the image from view
            image.parent().find('.actions.direct').fadeIn(500);
        }

        // function setCarouselMargins(image, width)
        // set the left and top margins for centering a carousel image after it has been rotated
        // image: jQuery object of carousel image to be rotated
        // width: width of the image container (integer)
        // image_width: specified width of image (this is used to override the image.width if the image has not yet been uploaded)
        // image_height: specified height of image (this is used to override the image.height of the image has not yet been uploaded)
        function setCarouselImageMargins(image, width, image_width, image_height){
            var height = '225px'; // carousel height

            if(image_width == undefined && image_height == undefined ){
              // console.log('calculating image width and height');
              image_width = image.width();
              image_height = image.height();
            }
            // console.log('carousel image width: ' + image_width);
            // console.log('carousel image height: ' + image_height);
            // console.log('carousel width: ' + width);

            if(image_height > image_width){
              var carousel_top_margin = (image_height - parseInt(height))/2*-1
              image.css('margin-top', carousel_top_margin+15);
            }
            var carousel_left_margin = (image_width-parseInt(width))/2*-1;  
            image.css('margin-left', carousel_left_margin);
            // console.log('carousel_left_margin: ' + carousel_left_margin);
            // console.log(' ');
        }

/////////////////////////////////////////
/////////////////////////////////////////
///////  VIDEO + SOUND FUNCTIONS  ///////
/////////////////////////////////////////
/////////////////////////////////////////

function callPlayer(frame_id, func, args) {
    if (window.jQuery && frame_id instanceof jQuery) frame_id = frame_id.get(0).id;
    var iframe = document.getElementById(frame_id);
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
    } else if (!domReady ||
               iframe && (!iframe.contentWindow || queue && !queue.ready) ||
               (!queue || !queue.ready) && typeof func === 'function') {
        if (!queue) queue = callPlayer.queue[frame_id] = [];
        queue.push([func, args]);
        if (!('poller' in queue)) {
            // keep polling until the document and frame is ready
            queue.poller = setInterval(function() {
                callPlayer(frame_id, 'listening');
            }, 250);
            // Add a global "message" event listener, to catch status updates:
            messageEvent(1, function runOnceReady(e) {
                if (!iframe) {
                    iframe = document.getElementById(frame_id);
                    if (!iframe) return;
                    if (iframe.tagName.toUpperCase() != 'IFRAME') {
                        iframe = iframe.getElementsByTagName('iframe')[0];
                        if (!iframe) return;
                    }
                }
                if (e.source === iframe.contentWindow) {
                    // Assume that the player is ready if we receive a
                    // message from the iframe
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

      // function stopiFrame(carousel)
      // stops all iframes when switching in carousel
      // carousel: jQuery carousel object
      function stopiFrame(carousel){
         var iframes = carousel.find('iframe');    
          for(var i =0; i< iframes.length; i++){
            var iframe = $(iframes[i])
             if(iframe.parents('.item').hasClass('active')){
                // console.log('stopping video ' + iframe.attr('id'));
                if(iframe.attr('src').indexOf("youtube") > 0){
                  callPlayer($(iframes[i]).attr('id'), "pauseVideo");
                }else{
                  iframe.attr('src', iframe.attr('src'));
                }
                
            }
          }
      }

      // function stopSoundcloud(carousel)
      // stop all soundcloud players in this carousel from playing
      // carousel: jQuery carousel object
      function stopSoundcloud(carousel){
        carousel.find('iframe').each(function(index,iframe){
          if (iframe.src.indexOf("soundcloud") >=0){
        //    console.log('stopping soundclouds');
            SC.Widget(iframe).pause();
          }
        });
      }

      // function stopHTMLVideo(carousel)
      // stop html players from playing in this carousel
      // carousel: jQuery carousel object
      function stopHTMLVideo(carousel){
          carousel.find('video').each(function(index, video){
          //    console.log('video: ' +  video);
              video.pause();
          });
      }

      // function reset_videos(carousel)
      // reset video (used to trigger playing of iframes in the carousel)
      // carousel: jQuery carousel object
      function reset_videos(carousel){
          // stop all videos
          stopiFrame(carousel);
          stopHTMLVideo(carousel);
      }

//////////////////////////////////////
//////////////////////////////////////
///////  CAROUSEL SLIDESHOWS   ///////
//////////////////////////////////////
//////////////////////////////////////

        // function loadCarousels(source)
        // load the image carousels on project pages
        function loadCarousels(source){
            // enable pointer cursor when user hovers over thumbnail gallery images
            $('.thumbGallery').addClass('view');

            // change cursor to pointer if hovering over thumbnails
            $('.thumbGallery img').on('hover', function(){
              // console.log('hovering over image from loadCarousel');
              $(this).css("cursor", "pointer");
            }, function(){
              $(this).css("cursor", "default");
            });

            // set photo active in carousel when thumbnail is clicked
            if(source!="edit"){
              $('.thumbGallery .image').on('click', function(){
                var child_image = $(this).find('img')
                var carouselID = child_image.attr("data-parent");
                var image = parseInt(child_image.attr("data-position"));

                // console.log('clicked on thumbnail ' + image + ' in carousel ' + carouselID);

                // slide to the element in the slideshow
                 $('.carousel.'+carouselID).carousel(image);
              });      
            }
        }

        // function setCarousel(image_src)
        // go to the specified image in carousel on the edit page
        // image_src: the id of the image (active record id)
        function setCarousel(image_id){
          // console.log('set carousel image');

          // find the position of the selected image and set it to active
          // console.log('image_id: ' + image_id);
          var image_index = $('.mainPhoto:not(".projectOverviewCarousel") img.'+image_id).closest('.item').index();
          // slide to that element
          $('.mainPhoto:not(".projectOverviewCarousel")').carousel(image_index);
       }

        /* carousel_video_iframe -  return embed code for video iframe (from youtube or vimeo)
           video_source = embed url for the youtube / vimeo video
           step_id = id of the step the video belongs to
           image_id = id of the image associated with the video
           active = whether or not the image is the first one in the carousel
        */

        function carousel_video_iframe(video_source, step_id, image_id, active){
            return '<div class="item embed_video ' + active +'"><div class="flex-video"><a class="fancybox" href="'+video_source+'" rel="gallery ' + step_id + '" data-fancybox-type="iframe"><iframe src="'+ video_source + '?enablejsapi=1" class="' + image_id + '" id="video_' + image_id + '" allowfullscreen="allowfullscreen"></iframe></a></div></div>'
        }

         /* carousel_video_player - return code to embed html 5 player for uploaded videos
           video_source = url of the video (from amazon s3)
           step_id = id of the step the video belongs to
           image_id = id of the image associated with the video
           active = whether or not the image is the first one in the carousel
        */

        function carousel_video_player(video_source_mp4, step_id, image_id, active){
            return '<div class="item s3_video ' + active + '"><div class="flex-video uploaded-video"><a class="fancybox fancy_video" href="'+video_source_mp4 +'" rel="gallery ' + step_id + '" data-fancybox-type="html"></a><video controls><source src="'+ video_source_mp4+ '" class="' + image_id + '" id="video_' + image_id + '" type="video/mp4"></video></div></div>'
        }

        /* carousel_video_player_lazy - return code to embed html 5 player for uploaded videos - with loazy loading!
           video_source = url of the video (from amazon s3)
           step_id = id of the step the video belongs to
           image_id = id of the image associated with the video
           active = whether or not the image is the first one in the carousel
        */

        function carousel_video_player_lazy(video_source_mp4, step_id, image_id, active){
            return '<div class="item s3_video ' + active + '"><div class="flex-video uploaded-video"><a class="fancybox fancy_video" href="'+video_source_mp4 +'" rel="gallery ' + step_id + '" data-fancybox-type="html"></a><video controls class="lazy"><source src="'+ ""+ '" class="' + image_id + '" id="video_' + image_id + '" type="video/mp4" data-src="'+ video_source_mp4 + '"></video></div></div>'
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

//////////////////////////////
///////  DESIGN FILES  ///////
//////////////////////////////
      
      /* function remove_design_file()
         removes a design file from the form
      */
      function remove_design_file(){
        console.log('removing existing design file');
        $('.file_to_remove').parents('.design_file_row').fadeOut('300');
        event.preventDefault();
      }

      /* function addRemoveLInks()
        show or hide remove file link for design files form
      */
      function addRemoveLinks(){
        $('.design_file_upload_fieldset').each( function(){
          if( $(this).find('label').length > 0 ){
             $(this).find('.remove_fields').show();
           }else {
             $(this).find('.remove_fields').hide();
          }
        });
      }

      /* function addField(input)
         add a new design file field to the form
      */
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

////////////////////////////////
///////  MISC FUNCTIONS  ///////
////////////////////////////////

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

      // function navArrowVisibility 
    // set the visibility of arrows in the projectTitleBar

      function navArrowVisibility(){
        // console.log('in navArrowVisibility');
        if(currentStep != stepIDs[stepIDs.length-1]){
          $('#projectTitleBar .fa-angle-right').css('visibility', 'visible');
          // console.log('making right nav visible');
        }else{
          $('#projectTitleBar .fa-angle-right').css('visibility', 'hidden');
        }
         $('#projectTitleBar .fa-angle-left').css('visibility', 'visible'); 
      }


///////////////////////////////////
///////  PAGE LOAD THINGS   ///////
///////////////////////////////////

$(function(){

  // load best in place and rest in place for editing project name, description
  $('.best_in_place').best_in_place();
  $('.rest-in-place').restInPlace();

  // add a design file field to the form  
  $('form').on('click', '.add_fields', function(event) {
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

    // start carousel
    $('.carousel.slide').carousel({
          interval: false
    });

    // initiate fancybox lightbox plugin - enable rotation features ony in edit mode
    var pageURL = window.location.pathname;

    // for fancybox video
    var $video_player, _videoHref, _videoPoster, _videoWidth, _videoHeight, _dataCaption, _player, _isPlaying = false;
    
    if(pageURL.indexOf('edit')>0 || pageURL.indexOf('new')>0){
      
      // we're on the edit page
        $(".fancybox").on('click', function(){
          // retrieve all link items from this gallery to use for determining fancybox type
          var gallery_array = $(this).attr('rel').split(/(\s+)/);
          var gallery_name = gallery_array[gallery_array.length-1];
          var galleryItems = $('a[rel*='+gallery_name+']');

          $('.fancybox').fancybox({
            helpers: {
              type: $(galleryItems[this.index]).data('fancyboxType'),
              overlay: {
                locked: false
              }
            },
            arrows: false,
            closeBtn: false,
            beforeLoad: function(){
               if($(galleryItems[this.index]).hasClass('fancy_video')){
                // console.log('LOADING VIDEO IN FANCYBOX');
                _videoHref = this.href;
                _videoWidth = $(window).width()*1.5;
                // console.log('videoWidth: ' + _videoWidth);
                this.content = "<video id='video_player' src='" + _videoHref + "' width='" + _videoWidth + "'  controls='controls' preload='none' ></video>";
                this.width = _videoWidth;
              }
            },
            beforeShow: function(){
              // console.log('in beforeShow of fancybox');
              if($('.fancybox-image').length>0){
                 $('.fancybox-wrap').css('display', 'none');
              }
              if($(galleryItems[this.index]).hasClass('fancy_video')){
                $('.fancybox-wrap').css('visibility', 'hidden');
              }
            },
            afterShow: function(){
               if($(galleryItems[this.index]).hasClass('fancy_video')){
                var $video_player = new MediaElementPlayer('#video_player', {
                      success : function (mediaElement, domObject) {
                          mediaElement.play(); // autoplay video (optional)
                          mediaElement.addEventListener('loadeddata', function(){
                            $.fancybox.toggle();
                            $('.fancybox-wrap').css('visibility', 'visible');
                          });
                      } // success
                  });
              }
              if($('.fancybox-image').length>0){
                 var src = $('.fancybox-image').attr('src');
                 // console.log('src: ' + src);
                 if(src.indexOf('image_path')>0){
                    var imageID = getFancyboxImageID();
                    var rotation = getFancyboxRotation(imageID);  
                 }else{
                  var rotation = getRotation($('.stepImage img[src="'+src+'"]'));
                 }
                 // console.log('fancybox rotation: ' + rotation);
                  if(rotation!=0){
                    fancyboxRotate(rotation);  
                 }
                 $('.fancybox-wrap').fadeIn();

              }
            }
        });
    });

    }else{
      var img_rotation = 0;
      
      // we're on the index page
      $('.fancybox').on('click', function(){
        // retrieve all link items from this gallery to use for determining fancybox type
        var gallery_name = $($(this).attr('rel').split(/(\s+)/)).get(-1);
        var galleryItems = $('a[rel*='+gallery_name+']');

        $(".fancybox").fancybox({
          helpers: {
            type: $(galleryItems[this.index]).data('fancyboxType'),
            overlay: {
              locked: false
            }
          }, 
          beforeLoad: function(){
            // console.log('fancybox-type: ' + $(galleryItems[this.index]).data('fancyboxType'));
            if($(galleryItems[this.index]).hasClass('fancy_video')){
              // console.log('LOADING VIDEO IN FANCYBOX');
              _videoHref = this.href;
              _videoWidth = $(window).width()*1.5;
              // console.log('videoWidth: ' + _videoWidth);
              this.content = "<video id='video_player' src='" + _videoHref + "' width='" + _videoWidth + "'  controls='controls' preload='none' ></video>";
              this.width = _videoWidth;
            }
            this.href = this.href + "?v=" + new Date().getTime(); // ensure image shown is not cached
            img_rotation = $(this.element).data('rotation');
            
          },
          afterLoad: function(){
            // add navigation dots
            var list = $("#links");
              
            if (!list.length) {    
                list = $('<ul id="links">');
            
                for (var i = 0; i < this.group.length; i++) {
                    $('<li data-index="' + i + '"><label></label></li>').click(function() { $.fancybox.jumpto( $(this).data('index'));}).appendTo( list );
                }
                list.appendTo( 'body' );
            }
            list.find('li').removeClass('active').eq( this.index ).addClass('active');
          },
          beforeShow: function(){
            if(typeof img_rotation != 'undefined' && img_rotation !=0){
                $('.fancybox-wrap').css('display', 'none');
                fancyboxRotate(parseInt(img_rotation));
            }
            if($(galleryItems[this.index]).hasClass('fancy_video')){
              $('.fancybox-wrap').css('visibility', 'hidden');
                // $('.fancybox-wrap').hide();
            }
          },
          afterShow: function(){
            if(typeof img_rotation != 'undefined' && img_rotation!=0){
              $('.fancybox-nav').hide();
              $('.fancybox-close').hide();
              $('.fancybox-title').hide();
              $('.fancybox-wrap').fadeIn();
              img_rotation =0;
            }
            if($(galleryItems[this.index]).hasClass('fancy_video')){
              var $video_player = new MediaElementPlayer('#video_player', {
                    success : function (mediaElement, domObject) {
                        mediaElement.play(); // autoplay video (optional)
                        mediaElement.addEventListener('loadeddata', function(){
                          $.fancybox.toggle();
                          $('.fancybox-wrap').css('visibility', 'visible');
                        });
                    } // success
                });
            }
          },
          beforeClose: function(){
            // remove links
            $("#links").remove();    
          }

        });
      });
    }

    // function clearCacheImages()
    // clears cache (to ensure image is show in correct orientation)
    function clearCacheImages(source){
        jQuery('img').each(function(){  
          jQuery(this).attr('src',jQuery(this).attr('src')+ '?' + (new Date()).getTime());  
        });  
    }

    $(document).ready(function(){
      clearCacheImages();
    })
});
