//Turn auto complete as widget latter
//(function($){
//  $.widget( "curate.auto_complete", {
//      options: {
//          field: null
//      },
//    get_autocomplete_opts:function(field) {
//        var autocomplete_opts = {
//            minLength: 2,
//            source: function( request, response ) {
//                $.getJSON( "/authorities/generic_files/" + field, {
//                    q: request.term
//                }, response );
//            },
//            focus: function() {
//                // prevent value inserted on focus
//                return false;
//            },
//            complete: function(event) {
//                $('.ui-autocomplete-loading').removeClass("ui-autocomplete-loading");
//            }
//        };
//        return autocomplete_opts;
//    }
//  });
//})(jQuery);