# -*- encoding : utf-8 -*-

class AddSourcefileType < Wagn::Migration
  def up
    if (source = Card.fetch('Source file'))
      source.update_attributes! :type_id=>Card::CardtypeID, :codename=>'source_file'
    else
      Card.create! :name=>'Source file', :type_id=>Card::CardtypeID, :codename=>'source_file'
    end
    year = Card.fetch "year"
    year.update_attributes! :codename=>'year'
    Card.create! :name=>'Metric', :type_id=>Card::CardtypeID, :codename=>'metric'
  end
end
