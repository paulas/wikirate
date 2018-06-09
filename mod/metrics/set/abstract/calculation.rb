card_accessor :formula, type_id: PhraseID
card_accessor :metric_variables

# @param [Hash] opts
# @option opts [card key] :company
# @option opts [String] :year
def update_value_for! opts
  formula_card.calculate_values_for(opts) do |year, value|
    if (ans = answer opts[:company], year)
      value ? ans.update_value(value) : ans.delete
    elsif value
      Answer.create_calculated_answer self, opts[:company], year, value
    end
  end
end

def normalize_value value
  value.to_s if value
end
