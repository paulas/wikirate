# name pattern: Metric+Subject Company+Year+Object Company

include_set Abstract::MetricChild, generation: 3
include_set Abstract::MetricAnswer
include_set Abstract::DesignerPermissions

require_field :value
require_field :source, when: :source_required?

def related_company
  name.tag
end

def related_company_card
  Card[related_company]
end

def name_parts
  %w[metric company year related_company]
end

def valid_related_company?
  (related_company_card&.type_id == Card::WikirateCompanyID) ||
    ActManager.include?(related_company)
end

def valid_answer_name?
  super && valid_related_company?
end

def value_type_code
  metric_card.value_type_code
end

def value_cardtype_code
  metric_card.value_cardtype_code
end

# has to happen after :set_answer_name,
# but always, also if :set_answer_name is not executed
event :add_count_answer, :prepare_to_store, changed: :content do
  count = company_count
  count += 1 if @action == :create
  add_count answer_name, count
end

event :add_inverse_count_answer, :prepare_to_store, changed: :content do
  count = inverse_company_count
  count += 1 if @action == :create
  add_count inverse_answer_name, count
end

def add_count name, count
  add_subcard name, type_id: Card::MetricAnswerID,
                    subfields: { value: { content: count, type_id: Card::NumberValueID } }
end

def update_counts!
  update_count! answer_name, company_count
  update_count! inverse_answer_name, inverse_company_count
end

def update_count! answer_name, count
  if (card = Card.fetch(answer_name))
    return if card.value.to_s == count.to_s

    card.field(:value).update_column :db_content, count.to_s
    Answer.find_by_answer_id(card.id)&.update_columns value: count.to_s,
                                                      numeric_value: count.to_i
  else
    Card.create! name: answer_name, type_id: Card::MetricAnswerID,
                 subfields: { value: { content: count } }
  end
end

# number of companies that have a relationship answer for this answer
def company_count
  return 0 unless answer_id
  Relationship.where(answer_id: answer_id).count
end

def inverse_company_count
  return 0 unless inverse_answer_id
  Relationship.where(
    metric_id: metric_id,
    year: year,
    object_company_id: related_company_card.id
  ).count
end

def answer_id
  @answer_id ||= Card.fetch_id answer_name
end

def answer_name
  name.left
end

def inverse_answer_name
  [metric_card.inverse, related_company, year].join "+"
end

def inverse_answer_id
  @inverse_answer_id ||= Card.fetch_id inverse_answer_name
end

def answer
  @answer ||= Answer.new editor_id: nil
end

format :html do
  view :open_content do
    bs do
      layout do
        row 3, 9 do
          column render_basic_details
          column do
            row 12 do
              column _render_expanded_details
            end
          end
        end
      end
    end
  end

  view :content_formgroup do
    card.add_subfield :year, content: card.year
    card.add_subfield :related_company, content: card.related_company
    super()
  end

  def legend
    subformat(card.metric_card).value_legend
  end
end

format :json do
  def atom
    super().merge year: card.year.to_s,
                  value: card.value,
                  import: card.imported?,
                  comments: field_nest(:discussion, view: :core),
                  subject_company: Card.fetch_name(card.company),
                  object_company: Card.fetch_name(card.related_company)
  end

  def molecule
    super().merge subject_company: nest(card.company, view: :atom),
                  object_company: nest(card.related_company, view: :atom)
  end
end
