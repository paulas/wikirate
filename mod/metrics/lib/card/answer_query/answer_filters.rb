class Card
  class AnswerQuery
    # filters based on year and children of the answer card
    # (as opposed to metric and company)
    module AnswerFilters
      CALCULATED_TYPE_IDS = [FormulaID, WikiRatingID, DescendantID, ScoreID].freeze
      CALCULATED_TYPE_ID_STRING = "(#{CALCULATED_TYPE_IDS.join ', '})".freeze

      # :exists/researched (known + unknown) is default case;
      # :all and :none are handled in AllQuery
      def status_query value
        case value.to_sym
        when :unknown
          filter :value, "Unknown"
        when :known
          filter :value, "Unknown", "<>"
        end
      end

      def updated_query value
        return unless (period = timeperiod value)

        filter :updated_at, Time.now - period, ">"
      end

      def year_query value
        if value.try(:to_sym) == :latest
          filter :latest, true
        else
          filter :year, value.to_i
        end
      end

      def check_query value
        case value
        when "Completed" then filter :checkers, nil, "IS NOT"
        when "Requested" then filter :check_requester, nil, "IS NOT"
        when "Neither"
          %i[checkers check_requester].each { |fld| filter fld, nil, "IS" }
        end
      end

      def value_query value
        case value
        when Array # category filters. eg ["option1", "option2"]
          filter :value, value
        when Hash  # numeric range filters. eg { from: 20, to: 30 }
          numeric_range_query value
        else       # keyword matching filter. eg "carbon"
          filter_like :value, value
        end
      end

      def calculated_query value
        @conditions <<
          (value.to_sym == :calculated ? calculated_condition : not_calculated_condition)
      end

      def numeric_range_query value
        filter :numeric_value, value[:from], ">=" if value[:from].present?
        filter :numeric_value, value[:to], "<" if value[:to].present?
      end

      def source_query value
        restrict_by_wql :answer_id,
                        type_id: Card::MetricAnswerID,
                        right_plus: [Card::SourceID, { refer_to: value }]
      end

      def related_company_group_query value
        company_id_field = "#{metric_card&.inverse? ? :subject : :object}_company_id"
        company_pointer_id = Card[value]&.wikirate_company_card&.id
        answer_ids = answer_ids_from_relationships company_id_field, company_pointer_id
        restrict_to_ids :answer_id, answer_ids
      end

      private

      def answer_ids_from_relationships company_id_field, referer_id
        answer_id_field = :"#{relationship_prefix}answer_id"
        relationship_relation(company_id_field, referer_id).distinct.pluck answer_id_field
      end

      # "relationship" in the wikirate sense. "relation" in the rails sense
      def relationship_relation company_id_field, referer_id
        Relationship.joins(
          "join card_references cr on cr.referee_id = relationships.#{company_id_field}"
        ).where(
          "cr.referer_id = #{referer_id} " \
          "and #{relationship_prefix}metric_id = #{metric_card.id}"
        )
      end

      def relationship_prefix
        @relationship_prefix ||= metric_card&.inverse? ? "inverse_" : ""
      end

      def calculated_condition
        "(metric_type_id IN #{CALCULATED_TYPE_ID_STRING} AND answer_id IS NULL)"
      end

      def not_calculated_condition
        "(metric_type_id NOT IN #{CALCULATED_TYPE_ID_STRING} " \
        "OR answer_id IS NOT NULL)"
      end

      def timeperiod value
        case value.to_sym
        when :today then
          1.day
        when :week then
          1.week
        when :month then
          1.month
        end
      end
    end
  end
end
