format :html do
  def with_header header, level: 3
    output [wrap_with("h#{level}", header), yield]
  end

  def standard_nest codename
    field_nest codename, view: :titled,
                         title: codename.cardname,
                         variant: "plural capitalized",
                         items: { view: :link }
  end

  view :menued do
    render_titled hide: [:title, :toggle], show: :menu
  end

  def tab_nest codename, args={}
    field_nest codename, args.reverse_merge(view: :menued, items: { view: :link })
  end

  def original_link url, opts={}
    text = opts.delete(:text) || "Visit Original"
    link_to text, opts.merge(path: url)
  end
end
