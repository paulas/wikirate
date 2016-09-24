describe Card::Set::Type::SourceImportFile do
  before do
    login_as "joe_user"
    test_csv = File.open "#{Rails.root}/mod/wikirate/spec/set/" \
                         "type/source_import_test.csv"
    @source_import_file = Card.create! name: "does it matter?",
                                       source_import_file: test_csv,
                                       type_id: Card::SourceImportFileID
    Card::Env.params["is_metric_import_update"] = "true"
  end

  def test_row_content args, input_title
    with_tag "td", text: args[:file_company]
    if args[:wikirate_company].present?
      with_tag "td", text: args[:wikirate_company]
    end
    with_tag "td", text: args[:source]
    test_row_inputs args, input_title
    with_tag "td", text: args[:status]
  end

  def test_row_inputs args, input_title
    input_args = ["input", with: {
      type: "text", name: "corrected_company_name[#{args[:row]}]"
    }]
    title_input_args = ["input", with: {
      type: "text", name: "title[#{args[:row]}]", value: input_title
    }]
    with_tag(*title_input_args)
    with_tag(*input_args) if args[:status] != "exact"
  end

  def with_row checked, args
    input_title = args.delete :input_title
    with = { type: "checkbox", id: "sources_", value: args.to_json }
    with[:checked] = "checked" if checked
    with_tag "tr" do
      with_tag "input", with: with
      test_row_content args, input_title
    end
  end

  def trigger_import data, title
    Card::Env.params[:sources] = data
    Card::Env.params[:title] = title
    Card::Env.params["is_source_import_update"] = "true"
    @source_import_file.update_attributes subcards: {}
    @source_import_file
  end

  def verify_subcard_content source, subcard_codename, expected, pointer=false
    subcard = source.fetch trait: subcard_codename
    if pointer
      expect(subcard.item_names).to include(expected)
    else
      expect(subcard.content).to eq(expected)
    end
  end

  describe "Import action" do
    context "correct info" do
      it "adds a correct source" do
        data = [{
          file_company: "Apple Inc", year: "2014",
          report_type: "Conflict Minerals Report",
          source: "http://example.com/12333214",
          title: nil, row: 1, wikirate_company: "Apple Inc", status: "exact",
          company: "Apple Inc"
        }]
        expected_title =
          "Apple Inc.-Corporate Social Responsibility Report-2013"
        title = { "1" => expected_title }
        source_file = trigger_import data, title
        expect(source_file.subcards.empty?).to be_falsy
        source_card = source_file.subcards[source_file.subcards.to_a[0]]

        verify_subcard_content source_card, :wikirate_title, expected_title
        verify_subcard_content source_card, :report_type,
                               "Conflict Minerals Report", true
        verify_subcard_content source_card, :wikirate_company,
                               "Apple Inc", true
        verify_subcard_content source_card, :year,
                               "2014", true
      end
    end

    context "existing sources" do
      context "with fields" do
        before do
          source_args = {
            "+title" => "hTc",
            "+company" => "[[Apple Inc]]",
            "+report_type" => "[[Conflict Minerals Report]]",
            "+year" => "[[2014]]"
          }
          @source_card = create_page "http://wagn.org", source_args
          data = [{
            file_company: "Samsung", year: "2013",
            report_type: "Corporate Social Responsibility Report",
            source: "http://wagn.org",
            title: nil, row: 1, wikirate_company: "Samsung", status: "exact",
            company: "Samsung"
          }]
          title = { "1" => "SiDan" }
          trigger_import data, title
        end
        it "won't update exisitng source title" do
          # to trigger a "clean" update
          data = [{
            file_company: "Samsung", year: "2013",
            report_type: "Corporate Social Responsibility Report",
            source: "http://wagn.org",
            title: nil, row: 1, wikirate_company: "Samsung", status: "exact",
            company: "Samsung"
          }]
          title = { "1" => "SiDan" }
          trigger_import data, title
          verify_subcard_content @source_card, :wikirate_title, "hTc"
          expect(@source_card.success[:slot]).to be_empty
        end
        it "updates exisitng source" do
          expected_report_type = "Corporate Social Responsibility Report"
          expected_company = "Samsung"
          verify_subcard_content @source_card, :report_type,
                                 expected_report_type, true
          verify_subcard_content @source_card, :wikirate_company,
                                 expected_company, true
          verify_subcard_content @source_card, :year, "2013", true
          feedback = @source_import_file.success[:slot][:updated_sources]
          expect(feedback).to include(["1", @source_card.name])
        end
      end
      context "without title" do
        before do
          @url = "http://wagn.org"
          @source_card = create_link_source @url
          data = [{
            file_company: "Apple Inc", year: "2014",
            report_type: "Conflict Minerals Report",
            source: "http://wagn.org",
            title: nil, row: 1, wikirate_company: "Apple Inc", status: "exact",
            company: "Apple Inc"
          }]
          expected_title = "hTc"
          title = { "1" => expected_title }
          trigger_import data, title
        end
        it "updates exisitng source" do
          verify_subcard_content @source_card, :wikirate_title, "hTc"
          feedback = @source_import_file.success[:slot][:updated_sources]
          expect(feedback).to include(["1", @source_card.name])
        end
        it "renders correct feedback html" do
          args = @source_import_file.success[:slot]
          html = @source_import_file.format.render_core args
          css_class = "alert alert-warning"
          expect(html).to have_tag(:div, with: { class: css_class }) do
            with_tag :h4, text: "Existing sources updated"
            with_tag :ul do
              with_tag :li, text: "Row 1: #{@source_card.name}"
            end
          end
        end
      end
    end

    context "duplicated sources in file" do
      before do
        @url = "http://example.com/12333214"
        data = [{
          file_company: "Apple Inc", year: "2014",
          report_type: "Conflict Minerals Report",
          source: @url,
          title: nil, row: 1, wikirate_company: "Apple Inc", status: "exact",
          company: "Apple Inc"
        }, {
          file_company: "Samsung", year: "2013",
          report_type: "Conflict Minerals Report",
          source: @url,
          title: nil, row: 2, wikirate_company: "Samsung", status: "exact",
          company: "Samsung"
        }]
        @expected_title =
          "Apple Inc.-Corporate Social Responsibility Report-2013"
        title = { "1" => @expected_title, "2" => "Si L Dan" }
        @source_file = trigger_import data, title
      end
      it "only adds the first source" do
        expect(@source_file.subcards.empty?).to be_falsy
        source_card = @source_file.subcards[@source_file.subcards.to_a[0]]

        verify_subcard_content source_card, :wikirate_title, @expected_title
        verify_subcard_content source_card, :report_type,
                               "Conflict Minerals Report", true
        verify_subcard_content source_card, :wikirate_company,
                               "Apple Inc", true
        verify_subcard_content source_card, :year,
                               "2014", true
        feedback = @source_file.success[:slot][:duplicated_sources]
        expect(feedback).to include(["2", @url])
      end
      it "renders correct feedback html" do
        html = @source_file.format.render_core @source_file.success[:slot]
        css_class = "alert alert-warning"
        expect(html).to have_tag(:div, with: { class: css_class }) do
          with_tag :h4, text: "Duplicated sources in import file."\
                              " Only the first one is used."
          with_tag :ul do
            with_tag :li, text: "Row 2: http://example.com/12333214"
          end
        end
      end
    end

    context "missing fields" do
      def sample_data
        [{
          file_company: "Apple Inc", year: "2014",
          source: "http://wagn.org",
          report_type: "Conflict Minerals Report",
          title: nil, row: 1, wikirate_company: "Apple Inc", status: "exact",
          company: "Apple Inc"
        }]
      end

      def sample_title
        expected_title =
          "Apple Inc.-Corporate Social Responsibility Report-2013"
        { "1" => expected_title }
      end

      it "misses source field" do
        data = sample_data
        data[0].delete :source
        source_file = trigger_import data, sample_title
        err_key = "import error (row 1)".to_sym
        err_msg = "source missing"
        expect(source_file.errors).to have_key(err_key)
        expect(source_file.errors[err_key]).to include(err_msg)
      end
      it "misses company field" do
        data = sample_data
        data[0].delete :wikirate_company
        source_file = trigger_import data, sample_title
        err_key = "import error (row 1)".to_sym
        err_msg = "wikirate_company missing"
        expect(source_file.errors).to have_key(err_key)
        expect(source_file.errors[err_key]).to include(err_msg)
      end
      it "misses report type field" do
        data = sample_data
        data[0].delete :report_type
        source_file = trigger_import data, sample_title
        err_key = "import error (row 1)".to_sym
        err_msg = "report_type missing"
        expect(source_file.errors).to have_key(err_key)
        expect(source_file.errors[err_key]).to include(err_msg)
      end
      it "misses year field" do
        data = sample_data
        data[0].delete :year
        source_file = trigger_import data, sample_title
        err_key = "import error (row 1)".to_sym
        err_msg = "year missing"
        expect(source_file.errors).to have_key(err_key)
        expect(source_file.errors[err_key]).to include(err_msg)
      end
    end
  end

  describe "import table" do
    subject { @source_import_file.format.render_import }
    it "shows correctly import table" do
      is_expected.to have_tag("table", with: { class: "import_table" }) do
        input_title = "Apple Inc.-Corporate Social Responsibility Report-2013"
        with_row true,
                 file_company: "Apple Inc.",
                 year: "2013",
                 report_type: "Corporate Social Responsibility Report",
                 source: "http://example.com/1233213",
                 title: nil,
                 row: 1,
                 wikirate_company: "Apple Inc.",
                 status: "exact",
                 company: "Apple Inc.",
                 input_title: input_title
        with_row true,
                 file_company: "Apple Inc",
                 year: "2014",
                 report_type: "Conflict Minerals Report",
                 source: "http://example.com/12333214",
                 title: "hello world",
                 row: 2,
                 wikirate_company: "Apple Inc",
                 status: "exact",
                 company: "Apple Inc",
                 input_title: "hello world"
        with_row true,
                 file_company: "Apple",
                 year: "2012",
                 report_type: "Conflict Minerals Report",
                 source: "http://example.com/123332345",
                 title: "hello world1",
                 row: 3,
                 wikirate_company: "Apple Inc.",
                 status: "partial",
                 company: "Apple Inc.",
                 input_title: "hello world1"
      end
    end
  end
end