RSpec.describe Card::Set::Type::Metric::Export do
  let(:metric) { Card["Joe User+researched number 2"] }

  describe "atom view" do
    subject { render_view :atom, { name: metric.name }, format: :json }

    specify do
      is_expected.to include(name: "Joe User+researched number 2",
                             id: metric.id,
                             url: "http://wikirate.org/Joe_User+researched_number_2.json",
                             type: "Metric",
                             designer: "Joe User",
                             title: "researched number 2",
                             question: nil,
                             value_type: ["Number"])
    end
  end

  describe "molecule view" do
    subject { render_view :molecule, { name: metric.name }, format: :json }

    specify do
      is_expected
        .to include(
          name: "Joe User+researched number 2",
          id: metric.id,
          url: "http://wikirate.org/Joe_User+researched_number_2.json",
          type: a_hash_including(name: "Metric"),
          answers_url: "http://wikirate.org/Joe_User+researched_number_2+Answer.json",
          ancestors: [
            a_hash_including(name: "Joe User"),
            a_hash_including(name: "researched number 2")
          ]
        )
    end
  end
end
