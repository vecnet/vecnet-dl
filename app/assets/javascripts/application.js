// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//
//= require jquery-ui-1.9.2/jquery.ui.core
//= require jquery-ui-1.9.2/jquery.ui.widget
//= require jquery-ui-1.9.2/jquery.ui.menu
//= require jquery-ui-1.9.2/jquery.ui.position
//= require jquery-ui-1.9.2/jquery.ui.autocomplete
//
//= require blacklight/blacklight
//
//= require bootstrap-dropdown
//= require bootstrap-button
//= require bootstrap-collapse
//= require bootstrap-tooltip
//= require bootstrap-popover
//= require bootstrap-typeahead
//
//= require manage_repeating_fields
//= require toggle_details
//= require help_modal
//= require auto_complete
//= require icon_toggle

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

$(function(){
  $(".ajax_modal_launch").on( 'click', function( e ){
    Vecnet.setup_autocomplete('#ajax_modal');
  });

  // custom css expression for a case-insensitive contains()
  jQuery.expr[':'].Contains = function(a,i,m){
    return (a.textContent || a.innerText || "").toUpperCase().indexOf(m[3].toUpperCase())>=0;
  };

  $('#ajax-modal').on('focus', '.autocomplete',function() {
    Vecnet.setup_autocomplete('#ajax_modal');
    var sorted_terms= Vecnet.unique(terms)
    $(this).autocomplete({
      source :  sorted_terms,
      minLength:1,
      select: function( event, ui ) {
        Vecnet.list_filter($('ul.facet-hierarchy'))
      },
      close: function( event, ui ) {
        if($('.filterinput').val().length == 0) {
          $('ul.facet-hierarchy').find('li').slideDown();
        }
      }
    });
  });

  //$('#ajax-modal').on('keyDown',".filterinput", Vecnet.list_filter($('ul.facet-hierarchy')));

  $('abbr').tooltip();
  $("a[rel=popover]").popover({ trigger: "hover" });
  $('.multi_value.control-group').manage_fields();
  $('.spatial_value.control-group').manage_fields();

  $('#generic_file_based_near').autocomplete(get_autocomplete_opts("location"))
  $('#based_near_add').autocomplete(get_autocomplete_opts("location"))

  $("a[rel=popover]").click(function() { return false;});

  $("#generic_file_subject")
    // don't navigate away from the field on tab when selecting an item
    .bind( "keydown", function( event ) {
      if ( event.keyCode === $.ui.keyCode.TAB &&
        $( this ).data( "autocomplete" ).menu.active ) {
        event.preventDefault();
    }
  }).autocomplete(get_autocomplete_opts("subject") );

    $("#subject_add")
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
            if ( event.keyCode === $.ui.keyCode.TAB &&
                $( this ).data( "autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        }).autocomplete(get_autocomplete_opts("subject") );

  function get_autocomplete_opts(field) {
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
});
