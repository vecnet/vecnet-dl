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
//= require vecnet
//= require manage_repeating_fields
//= require toggle_details
//= require help_modal
//= require icon_toggle
//= require permissions
//= require blacklight/hierarchy/hierarchy


$(function(){

   $('.pager').on('click', 'a.disabled', function(event) {
        event.preventDefault();
   });

  $('.advanced').on('click', function(event){
        $('#simple-search-form').toggleClass('hide');
  });
  $("#subject_modal").on( 'click', function( e ){
    Vecnet.setup_autocomplete('#ajax_modal');
  });
  $("#ajax-modal").on('shown', function() {
    Blacklight.do_hierarchical_facet_expand_contract_behavior()
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
  $("a[rel=popover]").popover({ html : true ,trigger: "hover" });
  $('.multi_value.control-group').manage_fields();
  $('.spatial_value.control-group').manage_fields();

  $('.based_near_with_autocomplete').autocomplete(Vecnet.get_autocomplete_opts("location"))
  $('#based_near_add').autocomplete(Vecnet.get_autocomplete_opts("location"))

  $("a[rel=popover]").click(function() { return false;});

  $(".subject_with_autocomplete")
    // don't navigate away from the field on tab when selecting an item
    .bind( "keydown", function( event ) {
      if ( event.keyCode === $.ui.keyCode.TAB &&
        $( this ).data( "autocomplete" ).menu.active ) {
        event.preventDefault();
    }
  }).autocomplete(Vecnet.get_autocomplete_opts("subject") );

	$(".species_with_autocomplete")
	// don't navigate away from the field on tab when selecting an item
		.bind( "keydown", function( event ) {
			if ( event.keyCode === $.ui.keyCode.TAB &&
					$( this ).data( "autocomplete" ).menu.active ) {
				event.preventDefault();
			}
		}).autocomplete(Vecnet.get_autocomplete_opts("species") );

	$("#subject_add")
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
					if ( event.keyCode === $.ui.keyCode.TAB &&
							$( this ).data( "autocomplete" ).menu.active ) {
							event.preventDefault();
					}
			}).autocomplete(Vecnet.get_autocomplete_opts("subject") );


});
