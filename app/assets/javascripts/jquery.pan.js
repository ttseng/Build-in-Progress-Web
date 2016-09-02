var panInterval;

(function( $ ){

    var getSize = function($element) {
        return {
            'width': $element.width(), 
            'height': $element.height()
        };
    };

    var toCoords = function(x, y) {
        return {'x': x, 'y': y};
    };

    var vectorsEqual = function(v1, v2) {
        return v1.x == v2.x && v1.y == v2.y;
    }

    $.fn.pan = function(options) {

        //Container is element this plugin is applied to;
        //we're pan it's child element, content
        var container = this;
        var content = this.children('#chart');

        //Precalculate the limits of panning - offset stores
        //the current amount of pan throughout
        var offset = toCoords(
            Number(content.css('left').replace('px', '')) | 0,
            Number(content.css('top').replace('px', ''))  | 0
        );
        
        var containerSize = getSize(container);
        var contentSize = getSize(content);

        var minOffset = toCoords(
            -contentSize.width + containerSize.width,
            -contentSize.height + containerSize.height
        );

        var maxOffset = toCoords(0, 0);

        //By default, assume mouse sensitivity border
        //is 25% of the smallest dimension
        var defaultMouseEdge = 0.25 * Math.min(
            containerSize.width,
            containerSize.height
        );

        var settings = $.extend( {
            'autoSpeedX'            : 0,
            'autoSpeedY'            : 0,
            'mouseControl'          : 'kinetic',
            'kineticDamping'        : 0.8,
            'mouseEdgeSpeed'        : 5,
            'mouseEdgeWidth'        : defaultMouseEdge,
            'proportionalSmoothing' : 0.5,
            'updateInterval'        : 50,
            'mousePan'              : null
        }, options);

        //Mouse state variables, set by bound mouse events below
        var mouseOver = false;
        var mousePanningDirection = toCoords(0, 0);
        var mousePosition = toCoords(0, 0);

        var dragging = false;
        var lastMousePosition = null;
        var kineticVelocity = toCoords(0, 0);

        //Delay in ms between updating position of content
        var updateInterval = settings.updateInterval;

        var onInterval = function() {
            
            var mouseControlHandlers = {
                'edge'          : updateEdge,
                'proportional'  : updateProportional,
                'kinetic'       : updateKinetic,
                'disable'       : disable
            };

            var currentHandler = settings.mouseControl;

            if(!mouseControlHandlers[currentHandler]()) {
                //The handler isn't active - just pan normally
                offset.x += settings.autoSpeedX;
                offset.y += settings.autoSpeedY;
            }
            
            //If the previous updates have take the content
            //outside the allowed min/max, bring it back in
            constrainToBounds();
            
            //If we're panning automatically, make sure we're
            //panning in the right direction if the content has
            //moved as far as it can go
            if(offset.x == minOffset.x) settings.autoSpeedX = Math.abs(settings.autoSpeedX);
            if(offset.x == maxOffset.x) settings.autoSpeedX = -Math.abs(settings.autoSpeedX);
            if(offset.y == minOffset.y) settings.autoSpeedY = Math.abs(settings.autoSpeedY);
            if(offset.y == maxOffset.y) settings.autoSpeedY = -Math.abs(settings.autoSpeedY);

            //Finally, update the position of the content
            //with our carefully calculated value
            content.css('left', offset.x + "px");
            content.css('top', offset.y + "px");
        }

        var disable = function(){

        }

        var updateEdge = function() {

            if(!mouseOver) return false;

            //The user's possibly maybe mouse-navigating,
            //so we'll find out what direction in case we need
            //to handle any callbacks
            var newDirection = toCoords(0, 0);
            
            //If we're in the interaction zones to either
            //end of the element, pan in response to the
            //mouse position.
            if(mousePosition.x < settings.mouseEdgeWidth) {
                offset.x += settings.mouseEdgeSpeed;
                newDirection.x = -1;
            }
            if (mousePosition.x > containerSize.width - settings.mouseEdgeWidth) {
                offset.x -= settings.mouseEdgeSpeed;
                newDirection.x = 1;
            }
            if(mousePosition.y < settings.mouseEdgeWidth) {
                offset.y += settings.mouseEdgeSpeed;
                newDirection.y = -1;
            }
            if (mousePosition.y > containerSize.height - settings.mouseEdgeWidth) {
                offset.y -= settings.mouseEdgeSpeed;
                newDirection.y = 1;
            }

            updateMouseDirection(newDirection);

            return true;
        }

        var updateProportional = function() {

            if(!mouseOver) return false;
            
            var rx = mousePosition.x / containerSize.width;
            var ry = mousePosition.y / containerSize.height;
            targetOffset = toCoords(
                (minOffset.x - maxOffset.x) * rx + maxOffset.x,
                (minOffset.y - maxOffset.y) * ry + maxOffset.y
            );

            var damping = 1 - settings.proportionalSmoothing;
            offset = toCoords(
                (targetOffset.x - offset.x) * damping + offset.x,
                (targetOffset.y - offset.y) * damping + offset.y
            )

            return true;
        }

        var updateKinetic = function() {
            // console.log('updating kinetic');
            if(dragging) {
                
                if(lastMousePosition == null) {
                    lastMousePosition = toCoords(mousePosition.x, mousePosition.y);    
                }

                kineticVelocity = toCoords(
                    mousePosition.x - lastMousePosition.x,
                    mousePosition.y - lastMousePosition.y
                );

                lastMousePosition = toCoords(mousePosition.x, mousePosition.y);
            }

            offset.x += kineticVelocity.x;
            offset.y += kineticVelocity.y;

            kineticVelocity = toCoords(
                kineticVelocity.x * settings.kineticDamping,
                kineticVelocity.y * settings.kineticDamping
            );

            //If the kinetic velocity is still greater than a small threshold, this
            //function is still controlling movement so we return true so autopanning
            //doesn't interfere.
            var speedSquared = Math.pow(kineticVelocity.x, 2) + Math.pow(kineticVelocity.y, 2);
            return speedSquared > 0.01
        }

        var constrainToBounds = function() {
            if(offset.x < minOffset.x) offset.x = minOffset.x;
            if(offset.x > maxOffset.x) offset.x = maxOffset.x;
            if(offset.y < minOffset.y) offset.y = minOffset.y;
            if(offset.y > maxOffset.y) offset.y = maxOffset.y;
        }

        var updateMouseDirection = function(newDirection) {
            if(!vectorsEqual(newDirection, mousePanningDirection)) {
                mousePanningDirection = newDirection;
                if(settings.mousePan) {
                   settings.mousePan(mousePanningDirection);
                }
            }   
        }

        this.bind('mousemove', function(evt) {
            mousePosition.x = evt.pageX - container.offset().left;
            mousePosition.y = evt.pageY - container.offset().top;
            mouseOver = true;
        });

        this.bind('mouseleave', function(evt) {
            mouseOver = false;
            dragging = false;
            lastMousePosition = null;
            updateMouseDirection(toCoords(0, 0));
        });

        this.bind('mousedown', function(evt) {
            dragging = true;
            return false; //Prevents FF from thumbnailing & dragging
        });

        this.bind('mouseup', function(evt) {
            dragging = false;
            lastMousePosition = null;
        });

        //Kick off the main panning loop and return
        //this to maintain jquery chainability
        panInterval = setInterval(onInterval, updateInterval);
        // console.log('current panInterval: ' + panInterval);
        return this;
    };

})( jQuery );