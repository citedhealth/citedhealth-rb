# frozen_string_literal: true

module CitedHealth
  # A health ingredient with dosage and form information.
  class Ingredient
    attr_reader :id, :name, :slug, :category, :mechanism,
                :recommended_dosage, :forms, :is_featured

    def initialize(id:, name:, slug:, category: "", mechanism: "",
                   recommended_dosage: {}, forms: [], is_featured: false)
      @id = id
      @name = name
      @slug = slug
      @category = category
      @mechanism = mechanism
      @recommended_dosage = recommended_dosage
      @forms = forms
      @is_featured = is_featured
    end

    def self.from_hash(hash)
      new(
        id: hash["id"],
        name: hash["name"],
        slug: hash["slug"],
        category: hash["category"] || "",
        mechanism: hash["mechanism"] || "",
        recommended_dosage: hash["recommended_dosage"] || {},
        forms: hash["forms"] || [],
        is_featured: hash["is_featured"] || false
      )
    end
  end

  # A health condition referenced in evidence links and the conditions API.
  class Condition
    attr_reader :slug, :name, :description, :meta_description,
                :prevalence, :symptoms, :risk_factors, :is_featured

    def initialize(slug:, name:, description: "", meta_description: "",
                   prevalence: "", symptoms: [], risk_factors: [], is_featured: false)
      @slug = slug
      @name = name
      @description = description
      @meta_description = meta_description
      @prevalence = prevalence
      @symptoms = symptoms
      @risk_factors = risk_factors
      @is_featured = is_featured
    end

    def self.from_hash(hash)
      new(
        slug: hash["slug"],
        name: hash["name"],
        description: hash["description"] || "",
        meta_description: hash["meta_description"] || "",
        prevalence: hash["prevalence"] || "",
        symptoms: hash["symptoms"] || [],
        risk_factors: hash["risk_factors"] || [],
        is_featured: hash["is_featured"] || false
      )
    end
  end

  # A glossary term explaining health and supplement terminology.
  class GlossaryTerm
    attr_reader :slug, :term, :short_definition, :definition,
                :abbreviation, :category

    def initialize(slug:, term:, short_definition: "", definition: "",
                   abbreviation: "", category: "")
      @slug = slug
      @term = term
      @short_definition = short_definition
      @definition = definition
      @abbreviation = abbreviation
      @category = category
    end

    def self.from_hash(hash)
      new(
        slug: hash["slug"],
        term: hash["term"],
        short_definition: hash["short_definition"] || "",
        definition: hash["definition"] || "",
        abbreviation: hash["abbreviation"] || "",
        category: hash["category"] || ""
      )
    end
  end

  # A curated guide on health topics and supplement usage.
  class Guide
    attr_reader :slug, :title, :content, :category, :meta_description

    def initialize(slug:, title:, content: "", category: "", meta_description: "")
      @slug = slug
      @title = title
      @content = content
      @category = category
      @meta_description = meta_description
    end

    def self.from_hash(hash)
      new(
        slug: hash["slug"],
        title: hash["title"],
        content: hash["content"] || "",
        category: hash["category"] || "",
        meta_description: hash["meta_description"] || ""
      )
    end
  end

  # A research paper from PubMed.
  class Paper
    attr_reader :id, :pmid, :title, :journal, :publication_year,
                :study_type, :citation_count, :is_open_access, :pubmed_link

    def initialize(id:, pmid:, title:, journal: "", publication_year: nil,
                   study_type: "", citation_count: 0, is_open_access: false,
                   pubmed_link: "")
      @id = id
      @pmid = pmid
      @title = title
      @journal = journal
      @publication_year = publication_year
      @study_type = study_type
      @citation_count = citation_count
      @is_open_access = is_open_access
      @pubmed_link = pubmed_link
    end

    def self.from_hash(hash)
      new(
        id: hash["id"],
        pmid: hash["pmid"],
        title: hash["title"],
        journal: hash["journal"] || "",
        publication_year: hash["publication_year"],
        study_type: hash["study_type"] || "",
        citation_count: hash["citation_count"] || 0,
        is_open_access: hash["is_open_access"] || false,
        pubmed_link: hash["pubmed_link"] || ""
      )
    end
  end

  # Nested ingredient reference within an evidence link.
  class NestedIngredient
    attr_reader :slug, :name

    def initialize(slug:, name:)
      @slug = slug
      @name = name
    end

    def self.from_hash(hash)
      new(
        slug: hash["slug"],
        name: hash["name"]
      )
    end
  end

  # An evidence link connecting an ingredient to a condition with a grade.
  class EvidenceLink
    attr_reader :id, :ingredient, :condition, :grade, :grade_label,
                :summary, :direction, :total_studies, :total_participants

    def initialize(id:, ingredient:, condition:, grade: "", grade_label: "",
                   summary: "", direction: "", total_studies: 0,
                   total_participants: 0)
      @id = id
      @ingredient = ingredient
      @condition = condition
      @grade = grade
      @grade_label = grade_label
      @summary = summary
      @direction = direction
      @total_studies = total_studies
      @total_participants = total_participants
    end

    def self.from_hash(hash)
      ingredient_data = hash["ingredient"] || {}
      condition_data = hash["condition"] || {}

      new(
        id: hash["id"],
        ingredient: NestedIngredient.from_hash(ingredient_data),
        condition: Condition.from_hash(condition_data),
        grade: hash["grade"] || "",
        grade_label: hash["grade_label"] || "",
        summary: hash["summary"] || "",
        direction: hash["direction"] || "",
        total_studies: hash["total_studies"] || 0,
        total_participants: hash["total_participants"] || 0
      )
    end
  end
end
