class CSVRow
  # Expects an url in row[:source].
  # A hash in extra_data[:source_map] is used to handle duplicates sources in
  # the same import act.
  module SourceImport
    def initialize row, index, import_manager
      super
      @source_map = import_manager.extra_data(:global)[:source_map]
    end

    def source_args
      @source_args ||= @csv_row
    end

    def source_subcard_args
      args = {
        "+*source_type" => { content: "[[Link]]" },
        "+Link" => { content: @source_args[:source], type_id: Card::PhraseID }
      }
      # args["+title"] = { content: @source_args[:title] } if @source_args.key?(:title)
      # TODO test if card get right type
      # (all pointer except title)
      [:title, :report_type, :company, :year].each do |name|
        next unless @source_args.key? name
        args["+#{name}"] = { content: @source_args[name] }
      end
      args
    end

    def import_source update_existing: true
      @source_map.fetch @source_args[:source] do |url|
        @source_map[url] = create_or_update_source update_existing
      end
    end

    def create_or_update_source update_existing
      duplicates = Card::Set::Self::Source.find_duplicates @source_args[:source]
      if duplicates.empty?
        create_source
      elsif update_existing
        resolve_source_duplication duplicates.first.left
      else
        duplicates.first.left
      end
    end

    def resolve_source_duplicates existing_source
      updated = false
      updated |= update_title_card existing_source
      updated |= update_existing_source existing_source
      return unless updated
      success[:updated_sources].push([@csv_row.row_index, existing_source.name])
    end

    def create_source
      pick_up_card_errors do
        source_card = add_card name: "", type_id: Card::SourceID,
                               subcards: source_subcard_args
        finalize_source_card source_card
      end
    end

    def finalize_source_card source_card
      Card::Env.params[:sourcebox] = "true"
      source_card.director.catch_up_to_stage :prepare_to_store

      # the pure source update doesn't finalize, don't know why
      if !Card.exists?(source_card.name) && source_card.errors.empty?
        source_card.director.catch_up_to_stage :finalize
      end
      Card::Env.params[:sourcebox] = nil
      source_card
    end

    def update_existing_source source_card, source_hash
      [:report_type, :company, :year].inject(false) do |updated, e|
        create_or_update_pointer_subcard(source_card, e, source_hash[e]) || updated
      end
    end

    def update_title_card source_card, source_hash
      title = Card::Env.params[:title][source_hash[:row].to_s]
      title_card = source_card.fetch trait: :wikirate_title,
                                     new: { content: title }
      return unless title_card.new?
      add_subcard title_card
    end

    def create_or_update_pointer_subcard source_card, trait, content
      trait = hashkey_to_codename trait
      trait_card = source_card.fetch trait: trait,
                                     new: { content: "[[#{content}]]" }
      if trait_card.new?
        add_subcard trait_card
      elsif !trait_card.item_names.include?(content)
        trait_card.add_item content
        add_subcard trait_card
      else
        return false
      end
      true
    end

    def hashkey_to_codename hashkey
      case hashkey
      when :company
        :wikirate_company
      else
        hashkey
      end
    end
  end

  def check_duplication_within_file
    source_url = @source_args[:source]
    if @source_map[source_url]
      msg = [@csv_row.row_index, source_url]
      success.params[:duplicated_sources].push(msg)
      throw :skip_row
    end
  end
end
