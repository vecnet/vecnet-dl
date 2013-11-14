Vecnet={}
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

Vecnet.get_autocomplete_opts=function(field) {
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
		complete: function(event) {
			$('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
		}
	};
	return autocomplete_opts;
};
