# frozen_string_literal: true

require_relative "test_helper"

class TestClient < Minitest::Test
  def setup
    @client = CitedHealth::Client.new(base_url: "https://citedhealth.com", timeout: 5)
  end

  # -- Version --

  def test_version
    refute_nil CitedHealth::VERSION
    assert_equal "0.2.0", CitedHealth::VERSION
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
end
