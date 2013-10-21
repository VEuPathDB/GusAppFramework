var biomatGraph = biomatGraph || {};

biomatGraph.setupScrollBars = function(element) {
  var graph_width = jQuery("#biomaterials img").width();
  //alert("image width: " + graph_width);
  var viewport_width = jQuery(window).width();
  //alert("viewport width: " + viewport_width);
  jQuery(".scroll1").css("width", viewport_width - 100);
  jQuery(".scroll2").css("width", viewport_width - 100);
  jQuery("#biomaterials").width(graph_width);
  jQuery("#dummy").width(graph_width);
  jQuery(function() {
	jQuery(".scroll1").scroll(function() {
	  jQuery(".scroll2").scrollLeft(jQuery(".scroll1").scrollLeft());
	  jQuery('.popupContext').hide();
	});
	jQuery(".scroll2").scroll(function(){
	  jQuery(".scroll1").scrollLeft(jQuery(".scroll2").scrollLeft());
	  jQuery('.popupContext').hide();
	});
  });
};

biomatGraph.setupPopups = function() {
  jQuery('#biomatGraph area').each(function () {
	var url = jQuery(this).attr('href');
	var id = url.split("=")[1].split("&");
	var title = "?";
	if(url.indexOf('node') >= 0) {
	  var type = url.split("=")[2];
	  if(type.indexOf('material') >= 0) {
	    title = "Characteristics";
	  }
	  else {
		title = "File Location";
	  }
	}
	else if(url.indexOf('edge') >= 0) {
	  title = "Parameter Settings";
	}
	jQuery(this).removeAttr('href');
	/* Fix for graphviz broken before v2.28 */
	var coords = jQuery(this).attr('coords');
	coords = coords.replace(/ /g,',');
	jQuery(this).attr('coords', coords);
    jQuery(this).qtip({
      content: {
    	title: { 
    	  text: title,
    	  button: true
    	},
        text: $("#text" + id),
      },
      position: {
    	viewport: $(window),
  		my: 'bottom left', 
  		at: 'top center',
  		adjust: {
  		  method: 'flipinvert'
  		}
  	  },
      show: {
  		event: 'click',
  		solo: true // Only show one tooltip at a time
      },
  	  hide: 'unfocus',
  	  style: {
  		tip: {
            corner: true,
            width: 10,
            height: 5
        },
  		classes: 'qtip-rounded qtip-shadow'
  	  }
	});
    if(url.indexOf('edge') >= 0) {
      biomatGraph.setupMenu(this, id);
    }
  });
  //alert("setup complete");
};

biomatGraph.setupMenu = function(label, id) {
      $(label).contextPopup({
	    title: 'Additional Information',
	    items: [
	      {label:'Description',
	       icon:'../css/info.ico',
	       action:function(e) { biomatGraph.getDescriptions(id, e) }
	      },
	      {label:'Performers',
	       icon:'../css/info.ico',
	       action:function(e) { biomatGraph.getPerformers(id, e) }
	      },
	      {label:'Spreadsheet Location',     icon:'../css/info.ico',  action:function() { alert('clicked Spreadsheet Location') } },
	    ]
      });
};

biomatGraph.getDescriptions = function(id, e) {
  //alert(e.pageY + "," + e.pageX);
  jQuery('#descriptions' + id).css( { top:e.pageY, left:e.pageX } );
  jQuery('.popupContext').hide();
  jQuery('#descriptions' + id).show();
};

biomatGraph.getPerformers = function(id, e) {
  //alert(e.pageY + "," + e.pageX);
  jQuery('#performers' + id).css( { top:e.pageY, left:e.pageX } );
  jQuery('.popupContext').hide();
  jQuery('#performers' + id).show();
};

jQuery(document).ready(function() {
  jQuery("#biomaterials").waitForImages(function() {
    biomatGraph.setupScrollBars();
    biomatGraph.setupPopups();
  });
});

jQuery(document).on('click', '.popupContext a.qtip-close', function() {
    $(this).parent().parent().hide();
});

