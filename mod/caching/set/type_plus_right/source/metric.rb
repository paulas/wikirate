# cache # of metrics with answers for that cite this source
include_set Abstract::AnswerTableCachedCount, target_type: :metric

def search_anchor
  { answer_id: answer_ids }
end

def answer_ids
  Card.search type_id: MetricAnswerID, return: :id,
              right_plus: [{ id: Card::SourceID }, { link_to: name.left }]
end

def skip_search?
  answer_ids.blank?
end

# recount no. of sources on metric
recount_trigger :type_plus_right, :metric_answer, :source do |changed_card|
  changed_card.item_cards.map do |source_card|
    source_card.fetch trait: :metric
  end.compact
end

format do
  def search_with_params _args={}
    card.search return: :card
  end
end
