var biomatGraph = biomatGraph || {};
/*
biomatGraph.setupScrollBars = function(element) {
  jQuery(".wait").hide();
  var graph_width = jQuery("#biomaterials img").width();
  //alert("image width: " + graph_width);
  jQuery("#biomaterials").width(graph_width);
  jQuery("#dummy").width(graph_width);
  $(function() {
	$(".scroll1").scroll(function() {
	  $(".scroll2").scrollLeft($(".scroll1").scrollLeft());
	});
	$(".scroll2").scroll(function(){
	  $(".scroll1").scrollLeft($(".scroll2").scrollLeft());
	});
  });  
};
*/
biomatGraph.setupPopups = function() {
  jQuery('#biomatGraph area').each(function () {
	var url = jQuery(this).attr('href');
	var id = jQuery(this).attr('href').split("=")[1];
	jQuery(this).removeAttr('href');
	var title = "?";
	if(url.indexOf('node') >= 0) {
	  title = "Biomaterial";
	}
	else if(url.indexOf('edge') >= 0) {
	  title = "Treatment";
	}

    jQuery(this).qtip({
      content: {
    	text: $("#textNode" + id)
      },
      show: {
  		event: 'click',
  		solo: true // Only show one tooltip at a time
      },
  	  hide: 'unfocus',
  	  style: {
  		classes: 'ui-tooltip-wiki ui-tooltip-light ui-tooltip-shadow'
  	  }
	});
  });
  alert("setup complete");
};


jQuery(document).ready(function() {
  jQuery("#biomaterials").waitForImages(function() {
    //biomatGraph.setupScrollBars();
    biomatGraph.setupPopups();
  });
});
