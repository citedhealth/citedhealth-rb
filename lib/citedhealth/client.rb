# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module CitedHealth
  # HTTP client for the Cited Health REST API.
  #
  # All methods return typed Ruby objects (Ingredient, Paper, EvidenceLink).
  # Zero runtime dependencies — uses only Ruby stdlib (net/http, json, uri).
  #
  #   client = CitedHealth::Client.new
  #   ingredient = client.get_ingredient("vitamin-d")
  #   puts ingredient.name  # => "Vitamin D"
  #
  class Client
    DEFAULT_BASE_URL = "https://citedhealth.com"
    DEFAULT_TIMEOUT  = 30

    def initialize(base_url: DEFAULT_BASE_URL, timeout: DEFAULT_TIMEOUT)
      @base_url = base_url.chomp("/")
      @timeout = timeout
    end

    # Search ingredients by query and/or category.
    #
    # @param query [String] search term (default: "")
    # @param category [String] filter by category (default: "")
    # @return [Array<Ingredient>] list of matching ingredients
    def search_ingredients(query: "", category: "")
      params = {}
      params[:q] = query unless query.empty?
      params[:category] = category unless category.empty?

      data = get("/api/ingredients/", params)
      results = data["results"] || []
      results.map { |h| Ingredient.from_hash(h) }
    end

    # Get a single ingredient by slug.
    #
    # @param slug [String] ingredient slug (e.g. "vitamin-d")
    # @return [Ingredient]
    # @raise [NotFoundError] if the ingredient does not exist
    def get_ingredient(slug)
      data = get("/api/ingredients/#{slug}/")
      Ingredient.from_hash(data)
    end

    # Get evidence linking an ingredient to a condition.
    #
    # @param ingredient_slug [String] ingredient slug
    # @param condition_slug [String] condition slug
    # @return [EvidenceLink] the first matching evidence link
    # @raise [NotFoundError] if no evidence exists for the pair
    def get_evidence(ingredient_slug:, condition_slug:)
      data = get("/api/evidence/", ingredient: ingredient_slug, condition: condition_slug)
      results = data["results"] || []
      raise NotFoundError, "No evidence found: #{ingredient_slug} × #{condition_slug}" if results.empty?

      EvidenceLink.from_hash(results.first)
    end

    # Get a single evidence link by ID.
    #
    # @param id [Integer] evidence link ID
    # @return [EvidenceLink]
    # @raise [NotFoundError] if the evidence link does not exist
    def get_evidence_by_id(id)
      data = get("/api/evidence/#{id}/")
      EvidenceLink.from_hash(data)
    end

    # Search research papers by query and/or publication year.
    #
    # @param query [String] search term (default: "")
    # @param year [Integer, nil] filter by publication year
    # @return [Array<Paper>] list of matching papers
    def search_papers(query: "", year: nil)
      params = {}
      params[:q] = query unless query.empty?
      params[:year] = year.to_s unless year.nil?

      data = get("/api/papers/", params)
      results = data["results"] || []
      results.map { |h| Paper.from_hash(h) }
    end

    # Get a single paper by PubMed ID.
    #
    # @param pmid [String] PubMed ID
    # @return [Paper]
    # @raise [NotFoundError] if the paper does not exist
    def get_paper(pmid)
      data = get("/api/papers/#{pmid}/")
      Paper.from_hash(data)
    end

    private

    def get(path, params = {})
      uri = URI("#{@base_url}#{path}")
      uri.query = URI.encode_www_form(params) unless params.empty?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      request["User-Agent"] = "citedhealth-rb/#{VERSION}"

      response = http.request(request)

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPNotFound
        raise NotFoundError, "Not found: #{path}"
      when Net::HTTPTooManyRequests
        retry_after = response["Retry-After"]&.to_i
        raise RateLimitError.new("Rate limit exceeded", retry_after: retry_after)
      else
        raise Error, "HTTP #{response.code}: #{response.body}"
      end
    end
  end
end
