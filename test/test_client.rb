# frozen_string_literal: true

require_relative "test_helper"

class TestClient < Minitest::Test
  def setup
    @client = CitedHealth::Client.new(base_url: "https://citedhealth.com", timeout: 5)
  end

  # -- Version --

  def test_version
    refute_nil CitedHealth::VERSION
    assert_equal "0.4.0", CitedHealth::VERSION
  end

  # -- Client init --

  def test_client_default_init
    client = CitedHealth::Client.new
    assert_instance_of CitedHealth::Client, client
  end

  def test_client_custom_base_url
    client = CitedHealth::Client.new(base_url: "https://custom.example.com")
    assert_instance_of CitedHealth::Client, client
  end

  # -- search_ingredients --

  def test_search_ingredients
    body = {
      "results" => [
        {
          "id" => 1,
          "name" => "Vitamin D",
          "slug" => "vitamin-d",
          "category" => "Vitamins",
          "mechanism" => "Fat-soluble vitamin",
          "recommended_dosage" => { "general" => "1000-4000 IU" },
          "forms" => ["D3", "D2"],
          "is_featured" => true
        }
      ]
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/ingredients/?q=vitamin")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.search_ingredients(query: "vitamin")

    assert_equal 1, results.length
    assert_instance_of CitedHealth::Ingredient, results.first
    assert_equal "Vitamin D", results.first.name
    assert_equal "vitamin-d", results.first.slug
    assert_equal "Vitamins", results.first.category
    assert_equal true, results.first.is_featured
    assert_equal ["D3", "D2"], results.first.forms
  end

  def test_search_ingredients_with_category
    body = { "results" => [] }.to_json

    stub_request(:get, "https://citedhealth.com/api/ingredients/?q=zinc&category=Minerals")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.search_ingredients(query: "zinc", category: "Minerals")
    assert_equal 0, results.length
  end

  def test_search_ingredients_empty
    body = { "results" => [] }.to_json

    stub_request(:get, "https://citedhealth.com/api/ingredients/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.search_ingredients
    assert_equal 0, results.length
  end

  # -- get_ingredient --

  def test_get_ingredient
    body = {
      "id" => 1,
      "name" => "Vitamin D",
      "slug" => "vitamin-d",
      "category" => "Vitamins",
      "mechanism" => "Regulates calcium absorption",
      "recommended_dosage" => { "general" => "1000-4000 IU" },
      "forms" => ["D3", "D2"],
      "is_featured" => true
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/ingredients/vitamin-d/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    ingredient = @client.get_ingredient("vitamin-d")

    assert_instance_of CitedHealth::Ingredient, ingredient
    assert_equal 1, ingredient.id
    assert_equal "Vitamin D", ingredient.name
    assert_equal "vitamin-d", ingredient.slug
    assert_equal "Regulates calcium absorption", ingredient.mechanism
    assert_equal({ "general" => "1000-4000 IU" }, ingredient.recommended_dosage)
  end

  # -- get_evidence --

  def test_get_evidence
    body = {
      "results" => [
        {
          "id" => 42,
          "ingredient" => { "slug" => "vitamin-d", "name" => "Vitamin D" },
          "condition" => { "slug" => "hair-loss", "name" => "Hair Loss" },
          "grade" => "B",
          "grade_label" => "Good",
          "summary" => "Moderate evidence supports supplementation",
          "direction" => "positive",
          "total_studies" => 12,
          "total_participants" => 1500
        }
      ]
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/evidence/?ingredient=vitamin-d&condition=hair-loss")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    evidence = @client.get_evidence(ingredient_slug: "vitamin-d", condition_slug: "hair-loss")

    assert_instance_of CitedHealth::EvidenceLink, evidence
    assert_equal 42, evidence.id
    assert_equal "B", evidence.grade
    assert_equal "Good", evidence.grade_label
    assert_equal "positive", evidence.direction
    assert_equal 12, evidence.total_studies
    assert_equal 1500, evidence.total_participants
    assert_instance_of CitedHealth::NestedIngredient, evidence.ingredient
    assert_equal "vitamin-d", evidence.ingredient.slug
    assert_instance_of CitedHealth::Condition, evidence.condition
    assert_equal "hair-loss", evidence.condition.slug
  end

  def test_get_evidence_empty
    body = { "results" => [] }.to_json

    stub_request(:get, "https://citedhealth.com/api/evidence/?ingredient=nothing&condition=nothing")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    assert_raises(CitedHealth::NotFoundError) do
      @client.get_evidence(ingredient_slug: "nothing", condition_slug: "nothing")
    end
  end

  # -- get_evidence_by_id --

  def test_get_evidence_by_id
    body = {
      "id" => 42,
      "ingredient" => { "slug" => "vitamin-d", "name" => "Vitamin D" },
      "condition" => { "slug" => "hair-loss", "name" => "Hair Loss" },
      "grade" => "B",
      "grade_label" => "Good",
      "summary" => "Moderate evidence",
      "direction" => "positive",
      "total_studies" => 12,
      "total_participants" => 1500
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/evidence/42/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    evidence = @client.get_evidence_by_id(42)

    assert_instance_of CitedHealth::EvidenceLink, evidence
    assert_equal 42, evidence.id
    assert_equal "Vitamin D", evidence.ingredient.name
  end

  # -- search_papers --

  def test_search_papers
    body = {
      "results" => [
        {
          "id" => 1,
          "pmid" => "12345678",
          "title" => "Vitamin D and Hair Growth",
          "journal" => "Journal of Dermatology",
          "publication_year" => 2023,
          "study_type" => "RCT",
          "citation_count" => 45,
          "is_open_access" => true,
          "pubmed_link" => "https://pubmed.ncbi.nlm.nih.gov/12345678/"
        }
      ]
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/papers/?q=vitamin+d")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.search_papers(query: "vitamin d")

    assert_equal 1, results.length
    assert_instance_of CitedHealth::Paper, results.first
    assert_equal "12345678", results.first.pmid
    assert_equal "Vitamin D and Hair Growth", results.first.title
    assert_equal 2023, results.first.publication_year
    assert_equal true, results.first.is_open_access
  end

  def test_search_papers_with_year
    body = { "results" => [] }.to_json

    stub_request(:get, "https://citedhealth.com/api/papers/?q=melatonin&year=2024")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.search_papers(query: "melatonin", year: 2024)
    assert_equal 0, results.length
  end

  # -- get_paper --

  def test_get_paper
    body = {
      "id" => 1,
      "pmid" => "12345678",
      "title" => "Vitamin D and Hair Growth",
      "journal" => "Journal of Dermatology",
      "publication_year" => 2023,
      "study_type" => "RCT",
      "citation_count" => 45,
      "is_open_access" => true,
      "pubmed_link" => "https://pubmed.ncbi.nlm.nih.gov/12345678/"
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/papers/12345678/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    paper = @client.get_paper("12345678")

    assert_instance_of CitedHealth::Paper, paper
    assert_equal "12345678", paper.pmid
    assert_equal "Journal of Dermatology", paper.journal
    assert_equal 45, paper.citation_count
  end

  # -- Error handling --

  def test_not_found_error
    stub_request(:get, "https://citedhealth.com/api/ingredients/nonexistent/")
      .to_return(status: 404, body: '{"detail":"Not found."}', headers: { "Content-Type" => "application/json" })

    assert_raises(CitedHealth::NotFoundError) do
      @client.get_ingredient("nonexistent")
    end
  end

  def test_rate_limit_error
    stub_request(:get, "https://citedhealth.com/api/ingredients/vitamin-d/")
      .to_return(status: 429, body: '{"detail":"Rate limit exceeded"}',
                 headers: { "Content-Type" => "application/json", "Retry-After" => "60" })

    error = assert_raises(CitedHealth::RateLimitError) do
      @client.get_ingredient("vitamin-d")
    end

    assert_equal 60, error.retry_after
  end

  def test_rate_limit_error_without_retry_after
    stub_request(:get, "https://citedhealth.com/api/ingredients/vitamin-d/")
      .to_return(status: 429, body: '{"detail":"Rate limit exceeded"}',
                 headers: { "Content-Type" => "application/json" })

    error = assert_raises(CitedHealth::RateLimitError) do
      @client.get_ingredient("vitamin-d")
    end

    assert_nil error.retry_after
  end

  def test_generic_error
    stub_request(:get, "https://citedhealth.com/api/ingredients/vitamin-d/")
      .to_return(status: 500, body: "Internal Server Error",
                 headers: { "Content-Type" => "text/plain" })

    error = assert_raises(CitedHealth::Error) do
      @client.get_ingredient("vitamin-d")
    end

    assert_match(/500/, error.message)
  end

  # -- list_conditions --

  def test_list_conditions
    body = {
      "results" => [
        {
          "slug" => "hair-loss",
          "name" => "Hair Loss",
          "description" => "A condition involving thinning or loss of hair",
          "meta_description" => "Evidence-based supplements for hair loss",
          "prevalence" => "Affects ~50% of men by age 50",
          "symptoms" => ["Thinning hair", "Receding hairline"],
          "risk_factors" => ["Genetics", "Stress"],
          "is_featured" => true
        }
      ]
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/conditions/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.list_conditions

    assert_equal 1, results.length
    assert_instance_of CitedHealth::Condition, results.first
    assert_equal "hair-loss", results.first.slug
    assert_equal "Hair Loss", results.first.name
    assert_equal true, results.first.is_featured
    assert_equal ["Thinning hair", "Receding hairline"], results.first.symptoms
  end

  def test_list_conditions_featured
    body = { "results" => [] }.to_json

    stub_request(:get, "https://citedhealth.com/api/conditions/?is_featured=true")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.list_conditions(is_featured: true)
    assert_equal 0, results.length
  end

  # -- get_condition --

  def test_get_condition
    body = {
      "slug" => "insomnia",
      "name" => "Insomnia",
      "description" => "Difficulty falling or staying asleep",
      "meta_description" => "Evidence-based supplements for insomnia",
      "prevalence" => "10-30% of adults",
      "symptoms" => ["Difficulty falling asleep", "Waking up too early"],
      "risk_factors" => ["Stress", "Irregular schedule"],
      "is_featured" => true
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/conditions/insomnia/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    condition = @client.get_condition("insomnia")

    assert_instance_of CitedHealth::Condition, condition
    assert_equal "insomnia", condition.slug
    assert_equal "Insomnia", condition.name
    assert_equal "Difficulty falling or staying asleep", condition.description
    assert_equal ["Stress", "Irregular schedule"], condition.risk_factors
  end

  # -- list_glossary --

  def test_list_glossary
    body = {
      "results" => [
        {
          "slug" => "bioavailability",
          "term" => "Bioavailability",
          "short_definition" => "The proportion of a substance that enters circulation",
          "definition" => "The fraction of an administered dose that reaches systemic circulation",
          "abbreviation" => "",
          "category" => "pharmacology"
        }
      ]
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/glossary/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.list_glossary

    assert_equal 1, results.length
    assert_instance_of CitedHealth::GlossaryTerm, results.first
    assert_equal "bioavailability", results.first.slug
    assert_equal "Bioavailability", results.first.term
    assert_equal "pharmacology", results.first.category
  end

  def test_list_glossary_with_category
    body = { "results" => [] }.to_json

    stub_request(:get, "https://citedhealth.com/api/glossary/?category=supplements")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.list_glossary(category: "supplements")
    assert_equal 0, results.length
  end

  # -- get_glossary_term --

  def test_get_glossary_term
    body = {
      "slug" => "rct",
      "term" => "Randomized Controlled Trial",
      "short_definition" => "A study where participants are randomly assigned to groups",
      "definition" => "A study design that randomly assigns participants to an experimental group or a control group",
      "abbreviation" => "RCT",
      "category" => "research"
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/glossary/rct/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    term = @client.get_glossary_term("rct")

    assert_instance_of CitedHealth::GlossaryTerm, term
    assert_equal "rct", term.slug
    assert_equal "Randomized Controlled Trial", term.term
    assert_equal "RCT", term.abbreviation
    assert_equal "research", term.category
  end

  # -- list_guides --

  def test_list_guides
    body = {
      "results" => [
        {
          "slug" => "vitamin-d-hair-loss",
          "title" => "Vitamin D and Hair Loss",
          "content" => "# Vitamin D and Hair Loss\n\nResearch shows...",
          "category" => "hair",
          "meta_description" => "Complete guide to vitamin D for hair loss"
        }
      ]
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/guides/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.list_guides

    assert_equal 1, results.length
    assert_instance_of CitedHealth::Guide, results.first
    assert_equal "vitamin-d-hair-loss", results.first.slug
    assert_equal "Vitamin D and Hair Loss", results.first.title
    assert_equal "hair", results.first.category
  end

  def test_list_guides_with_category
    body = { "results" => [] }.to_json

    stub_request(:get, "https://citedhealth.com/api/guides/?category=hair")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    results = @client.list_guides(category: "hair")
    assert_equal 0, results.length
  end

  # -- get_guide --

  def test_get_guide
    body = {
      "slug" => "melatonin-sleep",
      "title" => "Melatonin for Sleep",
      "content" => "# Melatonin for Sleep\n\nMelatonin is a hormone...",
      "category" => "sleep",
      "meta_description" => "Evidence-based guide to melatonin for sleep"
    }.to_json

    stub_request(:get, "https://citedhealth.com/api/guides/melatonin-sleep/")
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    guide = @client.get_guide("melatonin-sleep")

    assert_instance_of CitedHealth::Guide, guide
    assert_equal "melatonin-sleep", guide.slug
    assert_equal "Melatonin for Sleep", guide.title
    assert_equal "sleep", guide.category
    assert_match(/Melatonin is a hormone/, guide.content)
  end
end
