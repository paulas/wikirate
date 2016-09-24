include_set Abstract::SortAndFilter
include_set Abstract::MetricChild, generation: 1

def raw_content
  %({
      "left":{
        "type":"metric_value",
        #{wql_to_identify_related_metric_values}
      },
      "right":"value",
      "limit":0
    })
end

format :json do
  view :core do |_args|
    mvh = MetricValuesHash.new card.left
    card.item_cards(default_query: true).each do |value_card|
      mvh.add value_card
    end
    mvh.to_json
  end
end