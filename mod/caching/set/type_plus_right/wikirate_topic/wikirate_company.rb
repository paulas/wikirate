# cache # of companies related to this topic (=left) via answers for metrics that
# are tagged with this topic
include_set Abstract::AnswerTableCachedCount, target_type: :company

def search_anchor
  { metric_id: ids_of_metrics_tagged_with_topic }
end

def topic_name
  name.left_name
end

# when metric value is edited
recount_trigger :type, :metric_answer do |changed_card|
  next unless (metric_card = changed_card.metric_card)
  topic_company_type_plus_right_cards_for_metric metric_card
end

# ... when <metric>+topic is edited
recount_trigger :type_plus_right, :metric, :wikirate_topic do |changed_card|
  metric_card = changed_card.left
  topic_company_type_plus_right_cards_for_metric metric_card
end

class << self
  def topic_company_type_plus_right_cards_for_metric metric_card
    topic_names_for_metric(metric_card).map do |topic_name|
      # FIXME: validate topics so this is not a problem (?)
      next unless Card.fetch_type_id(topic_name) == Card::WikirateTopicID
      Card.fetch topic_name, :wikirate_company
    end.compact
  end

  def topic_names_for_metric metric_card
    topic_pointer = metric_card.fetch trait: :wikirate_topic
    return [] unless topic_pointer
    Abstract::CachedCount.pointer_card_changed_card_names topic_pointer
  end
end

def ids_of_metrics_tagged_with_topic
  Card.search type_id: MetricID,
              right_plus: [WikirateTopicID, { refer_to: name.left }],
              return: :id
end

def company_ids_by_metric_count
  Answer.group(:company_id)
        .where(metric_id: ids_of_metrics_tagged_with_topic)
        .order("count_metric_id desc")
        .limit(100)
        .distinct
        .count(:metric_id)
end

format do
  def search_with_params _args={}
    card.company_ids_by_metric_count.map { |company_id| Card[company_id] }
  end
end
