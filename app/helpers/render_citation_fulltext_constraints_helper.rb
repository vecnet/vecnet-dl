module RenderCitationFulltextConstraintsHelper

  # note: trying to over-ride render_constraints_query instead ended up
  # interfering with advanced_search_controller, which sometimes doesn't call
  # super. oh well.
  def render_constraints_filters(my_params = params)
    if my_params[:include_full_text]
      render_constraint_element(nil, "Included Fulltext", :escape_value => false, :remove => my_params.merge(:include_full_text => nil))
    else
      "".html_safe
    end + super(my_params)
  end

  def render_search_to_s_filters(my_params)
    if my_params[:include_full_text]
      render_search_to_s_element(nil, "(Included Citation Fulltext)")
    else
      ""
    end + super(my_params)
  end
end