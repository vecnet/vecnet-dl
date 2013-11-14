// This widget manages the adding and removing of repeating fields.
// There are a lot of assumptions about the structure of the classes and elements.
// These assumptions are reflected in the MultiValueInput class.

(function($){
  $.widget( "curate.manage_fields", {
    options: {
      change: null,
      add: null,
      remove: null
    },

    _create: function() {
      this.element.addClass("managed");
      $('.field-wrapper', this.element).addClass("input-append");

      this.controls = $("<span class=\"field-controls\">");
      this.remover  = $("<button class=\"btn btn-danger remove\"><i class=\"icon-white icon-minus\"></i><span>Remove</span></button>");
      this.adder    = $("<button class=\"btn btn-success add\"><i class=\"icon-white icon-plus\"></i><span>Add</span></button>");

      $('.field-wrapper', this.element).append(this.controls);
      $('.field-wrapper:not(:last-child) .field-controls', this.element).append(this.remover);
      $('.field-controls:last', this.element).append(this.adder);

      this._on( this.element, {
        "click .remove": "remove_from_list",
        "click .add": "add_to_list"
      });
    },

    add_to_list: function( event ) {
      event.preventDefault();

      var $activeField = $(event.target).parents('.field-wrapper'),
          $activeFieldControls = $activeField.children('.field-controls'),
          $removeControl = this.remover.clone(),
          $newField = $activeField.clone(),
          $listing = $('.listing', this.element);

      $('.add', $activeFieldControls).remove();
      $activeFieldControls.prepend($removeControl);

      $newField.children('input').val('');
      $listing.append($newField);
      this._trigger("add");
			console.log("attach autocomplete to location to "+ $newField.find('input[type=text]').hasClass("based_near_with_autocomplete"))
      // should we attach an auto complete based on the input
      if ($newField.find('input[type=text]').hasClass('based_near_with_autocomplete')) {
				console.log("attach autocomplete to location")
        $newField.find('input[type=text]').autocomplete(Vecnet.get_autocomplete_opts("location"));
      }
      else if ($newField.find('input[type=text]').hasClass('subject_with_autocomplete')) {
				console.log("attach autocomplete to subject")
				$newField.find('input[type=text]').autocomplete(Vecnet.get_autocomplete_opts("subject"));
      }
			else if ($newField.find('input[type=text]').hasClass('species_with_autocomplete')) {
				console.log("attach autocomplete to species")
				$newField.find('input[type=text]').autocomplete(Vecnet.get_autocomplete_opts("species"));
			}
      $newField.find('input[type=text]').focus();
      },

    remove_from_list: function( event ) {
      event.preventDefault();

      $(event.target)
        .parents('.field-wrapper')
        .remove();

      this._trigger("remove");
    },

    _destroy: function() {
      this.actions.remove();
      $('.field-wrapper', this.element).removeClass("input-append");
      this.element.removeClass( "managed" );
    }
  });

    /*function get_autocomplete_opts(field) {
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
    }*/

})(jQuery);
