(function( $ ){

	Vecnet={} ;
	Vecnet.selected_location_ids = new Array();
	Vecnet.setup_autocomplete = function(form_selector) {
		terms = $("li").map(function(){
			return $(this).data('term');
		}).get()
	}

	Vecnet.unique = function(list) {
		var result = [];
		$.each(list, function(i, e) {
			if ($.inArray(e, result) == -1) result.push(e);
		});
		return result;
	}

	Vecnet.list_filter= function(list){
		var filter = $('.filterinput').val();
		if(filter) {
			// this finds all links in a list that contain the input,
			// and hide the ones not containing the input while showing the ones that do
			$(list).find("a:not(:Contains(" + filter + "))").parents('li').slideUp();
			$(list).find("a:Contains(" + filter + ")").parents('li').slideDown();
		} else {
			$(list).find('li').slideDown();
		}
		return false;
	}

	Vecnet.get_autocomplete_opts=function(field){
		var autocomplete_opts = {
			minLength: 2,
			source: function( request, response ) {
				$.getJSON( "/authorities/generic_files/" + field, {
					q: request.term
				}, response );
			},
			focus: function() {
				// prevent value inserted on focus
				return false;
			},
			select: function( event, ui ) {
				var selectedObj = ui.item;
				if (field == 'location'){
					var location=selectedObj.label+"|"+selectedObj.value
					// add the selected item
					if ($.inArray(location, Vecnet.selected_location_ids) == -1) Vecnet.selected_location_ids.push(location);
				}
				$(this).val(selectedObj.label);
				return false;
			},
			change: function( event, ui ) {
				if (field == 'location'){
					var default_id= $(this).val().length == 0 ? "" : $(this).val()+"|0"
					var newlocation= ui.item? ui.item.label+"|"+ui.item.value : default_id;
					if ($.inArray(newlocation, Vecnet.selected_location_ids) == -1) Vecnet.selected_location_ids.push(newlocation);
					var hidden_field=  $('.geoname_location_with_id')
					hidden_field.val(Vecnet.selected_location_ids);
					console.log("Newterm: "+newlocation)
				}
			},
			close: function(event) {
				console.log("On Close autocomplete: "+Vecnet.selected_location_ids.join(";"))
				var hidden_field=  $('.geoname_location_with_id')
				hidden_field.val(Vecnet.selected_location_ids);
				$('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
			}
		};
		return autocomplete_opts;
	}

//    Vecnet.split=function( val ) {
//        var term=(val == undefined) ? [] : val.split( '/,\s' );
//        return term
//    }
})( jQuery );

