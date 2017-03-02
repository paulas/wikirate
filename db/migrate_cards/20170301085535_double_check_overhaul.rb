# -*- encoding : utf-8 -*-

class DoubleCheckOverhaul < Card::Migration
  def up
    ensure_card "check requested by", codename: "check_requested_by"
    ensure_card "request", codename: "request"
    ensure_card "check requested by+*right+*default", type_id: Card::PointerID
    Card::Cache.reset_all

    update_checked_by_cards
  end

  def update_checked_by_cards
    Card.search(right: { codename: "checked_by" }).each do |card|
      if card.item_names.first == "request"
        create_card [card, :check_requested_by],
                    content: "[[#{card.item_names.second}]]",
                    type_id: Card::PointerID
        card.update_attributes! content: card.item_names[2..-1].to_pointer_content
      end
    end
  end
end
