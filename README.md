# citedhealth

[![Gem Version](https://badge.fury.io/rb/citedhealth.svg)](https://rubygems.org/gems/citedhealth)
[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%203.0-red)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen)](https://rubygems.org/gems/citedhealth)

Ruby client for the [Cited Health](https://citedhealth.com) API. Search evidence-based health supplement ingredients, research papers, and evidence links grading ingredient-condition relationships. Zero runtime dependencies -- uses only Ruby stdlib (`net/http`, `json`, `uri`).

Cited Health is an evidence-based supplement research platform providing curated data on 74 ingredients, 30 health conditions, 2,881 PubMed papers, and 152 graded evidence links connecting supplements to outcomes.

> **Explore the research at [citedhealth.com](https://citedhealth.com)** -- [Ingredients](https://citedhealth.com/ingredients/), [Evidence](https://citedhealth.com/evidence/), [Research Papers](https://citedhealth.com/papers/)

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [API Methods](#api-methods)
  - [Ingredients](#ingredients)
  - [Evidence Links](#evidence-links)
  - [Research Papers](#research-papers)
- [Error Handling](#error-handling)
- [Types](#types)
- [Learn More](#learn-more)
- [License](#license)

## Install

```bash
gem install citedhealth
```

Or add to your Gemfile:

```ruby
gem "citedhealth"
```

## Quick Start

```ruby
require "citedhealth"

client = CitedHealth::Client.new

# Search for ingredients related to hair health
ingredients = client.search_ingredients(query: "biotin")
puts ingredients.first.name        # => "Biotin"
puts ingredients.first.category    # => "Vitamins"

# Get detailed ingredient information
vitamin_d = client.get_ingredient("vitamin-d")
puts vitamin_d.mechanism           # => "Fat-soluble vitamin..."
puts vitamin_d.recommended_dosage  # => {"general" => "1000-4000 IU"}

# Look up evidence linking an ingredient to a condition
evidence = client.get_evidence(
  ingredient_slug: "vitamin-d",
  condition_slug: "hair-loss"
)
puts evidence.grade        # => "B"
puts evidence.grade_label  # => "Good"
puts evidence.summary      # => "Moderate evidence supports..."

# Search research papers from PubMed
papers = client.search_papers(query: "melatonin sleep", year: 2024)
puts papers.first.title    # Paper title
puts papers.first.journal  # Journal name
```

## API Methods

### Ingredients

```ruby
# Search ingredients by keyword and/or category
results = client.search_ingredients(query: "vitamin", category: "Vitamins")
results.each { |i| puts "#{i.name} (#{i.category})" }

# Get a single ingredient by slug
ingredient = client.get_ingredient("magnesium")
puts ingredient.name               # => "Magnesium"
puts ingredient.forms              # => ["Glycinate", "Citrate", ...]
puts ingredient.is_featured        # => true
```

### Evidence Links

```ruby
# Find evidence for a specific ingredient-condition pair
evidence = client.get_evidence(
  ingredient_slug: "melatonin",
  condition_slug: "insomnia"
)
if evidence
  puts "#{evidence.grade_label}: #{evidence.summary}"
  puts "Studies: #{evidence.total_studies}, Participants: #{evidence.total_participants}"
end

# Get evidence link by ID
evidence = client.get_evidence_by_id(42)
puts evidence.ingredient.name  # => "Vitamin D"
puts evidence.condition.name   # => "Hair Loss"
```

### Research Papers

```ruby
# Search papers by keyword
papers = client.search_papers(query: "collagen skin")
papers.each do |paper|
  puts "#{paper.title} (#{paper.journal}, #{paper.publication_year})"
  puts "  Citations: #{paper.citation_count}, Open access: #{paper.is_open_access}"
end

# Filter by publication year
recent = client.search_papers(query: "ashwagandha", year: 2025)

# Get a paper by PubMed ID
paper = client.get_paper("12345678")
puts paper.pubmed_link  # => "https://pubmed.ncbi.nlm.nih.gov/12345678/"
```

## Error Handling

```ruby
begin
  client.get_ingredient("nonexistent")
rescue CitedHealth::NotFoundError => e
  puts "Not found: #{e.message}"
rescue CitedHealth::RateLimitError => e
  puts "Rate limited. Retry after #{e.retry_after} seconds"
rescue CitedHealth::Error => e
  puts "API error: #{e.message}"
end
```

| Exception | HTTP Status | Description |
|-----------|-------------|-------------|
| `CitedHealth::NotFoundError` | 404 | Resource does not exist |
| `CitedHealth::RateLimitError` | 429 | Too many requests (check `retry_after`) |
| `CitedHealth::Error` | Other | General API or network error |

## Types

All API responses are returned as typed Ruby objects with `attr_reader` accessors.

| Class | Fields |
|-------|--------|
| `Ingredient` | `id`, `name`, `slug`, `category`, `mechanism`, `recommended_dosage`, `forms`, `is_featured` |
| `Condition` | `slug`, `name` |
| `Paper` | `id`, `pmid`, `title`, `journal`, `publication_year`, `study_type`, `citation_count`, `is_open_access`, `pubmed_link` |
| `EvidenceLink` | `id`, `ingredient`, `condition`, `grade`, `grade_label`, `summary`, `direction`, `total_studies`, `total_participants` |
| `NestedIngredient` | `slug`, `name` |

## Learn More

- **Cited Health**: [citedhealth.com](https://citedhealth.com) -- Evidence-based supplement research
- **API Documentation**: [citedhealth.com/developers/](https://citedhealth.com/developers/)
- **Hair Health**: [haircited.com](https://haircited.com) -- Supplements for hair loss and growth
- **Sleep Health**: [sleepcited.com](https://sleepcited.com) -- Supplements for sleep quality
- **Source Code**: [github.com/citedhealth/citedhealth-rb](https://github.com/citedhealth/citedhealth-rb)

## License

MIT -- see [LICENSE](LICENSE) for details.
