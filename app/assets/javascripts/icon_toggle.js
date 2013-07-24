$(function(){
    /*
     * facets lists
     */
    $("li.expandable").click(function(){
        $(this).next("ul").slideToggle();

        $(this).find('i').toggleClass("icon-chevron-down");
    });

    $("li.expandable_new").click(function(){
        $(this).find('i').toggleClass("icon-chevron-down");
    });

    $(".sorts-dash").click(function(){
        var itag =$(this).find('i');
        toggle_icon(itag);
        sort = itag.attr('class') == "icon-caret-down" ? itag.attr('id')+' desc':  itag.attr('id') +' asc';
        $('#sort').val(sort).selected = true;
        $(".icon-refresh").parent().click();
    });
    $(".sorts").click(function(){
        var itag =$(this).find('i');
        toggle_icon(itag);
        sort = itag.attr('class') == "icon-caret-down" ? itag.attr('id')+' desc':  itag.attr('id');
        $('input[name="sort"]').attr('value', sort);
        $(".icon-search").parent().click();
    })

    // show/hide more information on the dashboard when clicking
    // plus/minus
    $('.icon-plus').on('click', function() {
        //this.id format: "expand_NNNNNNNNNN"
        var a = this.id.split("expand_");
        if (a.length > 1) {
            var docId = a[1];
            $("#detail_"+docId).toggle();
            if( $("#detail_"+docId).is(":hidden") ) {
                $("#expand_"+docId).attr("class", "icon-plus icon-large");
            }
            else {
                $("#expand_"+docId).attr("class", "icon-minus icon-large");
            }
        }
        return false;
    });
});

/*
 * begin functions
 */

function toggle_icon(itag){
    itag.toggleClass("icon-caret-down");
    itag.toggleClass("icon-caret-up");
}