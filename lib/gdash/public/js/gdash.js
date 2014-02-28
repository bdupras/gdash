(function() {
    var exitFullscreen = function(event) {
        if(event.keyCode == 27) {
            window.location = window.location.origin + window.location.pathname;
        }
    };

    var refreshGraphs = function() {
        $('img').each(function(i, img){
            var src = $(img).attr('src') &&  $(img).attr('src').split('?');
            if(src) {
				if( src[0] && src[1] ) {
                	var base = src[0], query = $.deparam(src[1]);
                	query._t = Date.now();
                	$(img).attr('src', base + '?' + $.param(query));
				}
            }
        });
    };

    var enlargeGraph = function(e) {
        if(e.metaKey || e.ctrlKey) {
            return true;
        } else {
            var element = $(e.target);
            
            $("#xxlarge-lightbox img").attr("src", element.attr("xxlarge"));
            $("#xxlarge-lightbox").lightbox();
                
            return false;
        }
    };

    var startAutoScroll = function() {
        var viewport = $(window),
            autoscrolls = $('div.autoscroll'),
            position = 0,
            top = 0;

        setInterval(function() {
            var element = $(autoscrolls[position]),
                remaining = 0;

            $(autoscrolls.slice(position++)).each(function(i, el) {
                remaining += $(el).height();
            });

            top += element.height();

            if(remaining < viewport.height()) {
                top = position = 0;
            }
            
            $('html, body').animate({ scrollTop: top });

        }, 5000);
    };
    
    var toggle = function() {
        var fullscreen = window.location.hash === '#fullscreen';

        $('body').toggleClass('fullscreen', fullscreen);

        $('.fullscreen-toggle').attr('href', fullscreen ? '#' : '#fullscreen');

        $('.fullscreen-expanded').toggleClass('span12', fullscreen);
        $('.fullscreen-expanded').toggleClass('span10', !fullscreen);

        if (fullscreen) {
            $(document.body).keyup(exitFullscreen);
            startAutoScroll();
        }
    };

    var toggleTitles = function() {
        $('div.hidden-title').each(function(i, div) {
            if( $(div).css('display') == 'none') {
                $(div).css('display', 'inline')
            } else {
                $(div).css('display', 'none')
            }
        });
    }

    $(document).ready(function(){
        toggle();
        $(window).on('hashchange', toggle);
        
		$('img').each(function(i, img){
            var src = $(img).attr('src') &&  $(img).attr('src').split('?');
            if(src) {
				$(img).error( function() { $(img).attr('src', '/img/missing.png'); } );
            }
        });
        setInterval(refreshGraphs, GDash.refreshInterval * 1000);

        $('.snapshot').click(function() {
            return confirm('Snapshotting GDash will take a long time and a potentially large amount of disk space. Are you sure you want to continue?');
        });

        $(".click-enlarge").click(enlargeGraph);

        $(document).keypress(function(e) {
            if(e.which == 116) {
                toggleTitles();
            }
        });
    });
})();
