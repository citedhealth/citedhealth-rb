# citedhealth

[![Gem Version](https://badge.fury.io/rb/citedhealth.svg)](https://rubygems.org/gems/citedhealth)
[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%203.0-red)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Zero Dependencies](https://img.shields.io/badge/dependencies-0-brightgreen)](https://rubygems.org/gems/citedhealth)
[![GitHub stars](https://agentgif.com/badge/github/citedhealth/citedhealth-rb/stars.svg)](https://github.com/citedhealth/citedhealth-rb)

Ruby client for the [Cited Health](https://citedhealth.com) API. Search evidence-based health supplement ingredients, conditions, research papers, evidence links, glossary terms, and guides. Zero runtime dependencies -- uses only Ruby stdlib (`net/http`, `json`, `uri`).

Cited Health is an evidence-based supplement research platform across 6 sites providing curated data on 188 ingredients, 84 health conditions, 6,197 PubMed papers, and graded evidence links connecting supplements to outcomes.

> **Explore the research at [citedhealth.com](https://citedhealth.com)** -- [Ingredients](https://citedhealth.com/ingredients/), [Evidence](https://citedhealth.com/api/evidence/), [Research Papers](https://citedhealth.com/papers/) · [Hair](https://haircited.com) · [Sleep](https://sleepcited.com) · [Gut](https://gutcited.com) · [Immune](https://immunecited.com) · [Brain](https://braincited.com)

<p align="center">
  <a href="https://agentgif.com/YdiLe4Ln"><img src="https://media.agentgif.com/YdiLe4Ln.gif" alt="citedhealth Ruby CLI demo — search ingredients, evidence grades, and PubMed papers" width="800"></a>
</p>

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [Command-Line Interface](#command-line-interface)
- [What You Can Do](#what-you-can-do)
  - [Search Supplement Ingredients](#search-supplement-ingredients)
  - [Check Evidence Grades](#check-evidence-grades)
  - [Search PubMed Papers](#search-pubmed-papers)
  - [Browse Health Conditions](#browse-health-conditions)
  - [Look Up Glossary Terms](#look-up-glossary-terms)
  - [Read Health Guides](#read-health-guides)
- [Error Handling](#error-handling)
- [Evidence Grades](#evidence-grades)
- [API Reference](#api-reference)
- [Learn More About Evidence-Based Supplements](#learn-more-about-evidence-based-supplements)
- [Also Available](#also-available)
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
  condition_slug: "nutritional-deficiency-hair-loss"
)
puts evidence.grade        # => "B"
puts evidence.grade_label  # => "Good"
puts evidence.summary      # => "Moderate evidence supports..."

# Search research papers from PubMed
papers = client.search_papers(query: "melatonin sleep", year: 2024)
puts papers.first.title    # Paper title
puts papers.first.journal  # Journal name
```

## Command-Line Interface

Install the gem and use the `citedhealth` command directly from your terminal:

```bash
gem install citedhealth
```

### Search ingredients

```bash
citedhealth ingredients biotin
citedhealth ingredients --category Vitamins
```

### Get ingredient details

```bash
citedhealth ingredient vitamin-d
```

### Check evidence grades

```bash
citedhealth evidence biotin nutritional-deficiency-hair-loss
```

### Search research papers

```bash
citedhealth papers melatonin --year 2024
```

### Get paper by PubMed ID

```bash
citedhealth paper 12345678
```

### List conditions

```bash
citedhealth conditions
citedhealth conditions --featured
```

### Get condition details

```bash
citedhealth condition hair-loss
```

### Browse glossary

```bash
citedhealth glossary
citedhealth glossary -c supplements
```

### Get glossary term

```bash
citedhealth glossary-term bioavailability
```

### List guides

```bash
citedhealth guides
citedhealth guides -c hair
```

### Get guide details

```bash
citedhealth guide vitamin-d-hair-loss
```

### Output formats

By default, output is pretty-printed JSON. Use `--json` for compact JSON (useful for piping):

```bash
citedhealth ingredients biotin --json | jq '.[] | .name'
```

## What You Can Do

### Search Supplement Ingredients

Find ingredients by name or filter by category. Each ingredient includes mechanism of action, recommended dosage by population, available forms, and evidence linkage.

| Category | Examples |
|----------|---------|
| vitamins | Biotin, Vitamin D, Vitamin C |
| minerals | Magnesium, Zinc, Iron |
| amino-acids | L-Theanine, Tryptophan, Glycine |
| herbs | Ashwagandha, Valerian, Melatonin |

```ruby
client = CitedHealth::Client.new

# Search by keyword — returns matching ingredients
results = client.search_ingredients(query: "vitamin", category: "Vitamins")
results.each { |i| puts "#{i.name} (#{i.category})" }

# Get a specific ingredient with full details
magnesium = client.get_ingredient("magnesium")
puts magnesium.mechanism           # "Essential mineral cofactor..."
puts magnesium.recommended_dosage  # {"general" => "200-400mg"}
puts magnesium.forms               # ["Glycinate", "Citrate", ...]
```

Learn more: [Browse Ingredients](https://citedhealth.com/) · [Evidence Database](https://citedhealth.com/api/evidence/) · [Developer Docs](https://citedhealth.com/developers/)

### Check Evidence Grades

Every ingredient-condition pair has an evidence grade calculated from peer-reviewed PubMed studies. Grades reflect the strength, consistency, and quantity of evidence.

```ruby
client = CitedHealth::Client.new

# Get evidence for a specific ingredient-condition pair
evidence = client.get_evidence(
  ingredient_slug: "melatonin",
  condition_slug: "insomnia"
)
puts "Grade #{evidence.grade}: #{evidence.total_studies} studies"
# Grade A: 15 studies

# Evidence includes direction of effect
puts evidence.direction    # "positive" | "negative" | "neutral" | "mixed"
puts evidence.summary      # Human-readable summary

# Fetch by ID if you already know it
ev = client.get_evidence_by_id(42)
puts "#{ev.ingredient.name} for #{ev.condition.name}"
```

Learn more: [Evidence Reviews](https://citedhealth.com/api/evidence/) · [Grading Methodology](https://citedhealth.com/editorial-policy/) · [Hair Health](https://haircited.com) · [Sleep Health](https://sleepcited.com)

### Search PubMed Papers

All 6,197 papers are indexed from PubMed and enriched with citation data from Semantic Scholar. Filter by keyword or publication year.

```ruby
client = CitedHealth::Client.new

# Search papers by title/abstract keyword
papers = client.search_papers(query: "collagen skin")
papers.each do |paper|
  # Each paper includes PMID, journal, citation count, open access status
  puts "[PMID #{paper.pmid}] #{paper.title} (#{paper.publication_year})"
  puts "  #{paper.citation_count} citations — #{paper.pubmed_link}"
end

# Filter by publication year
recent = client.search_papers(query: "ashwagandha", year: 2025)

# Fetch a specific paper by PubMed ID
paper = client.get_paper("12345678")
puts paper.journal     # Journal name
puts paper.study_type  # "RCT", "Meta-Analysis", etc.
```

Learn more: [Browse Papers](https://citedhealth.com/papers/) · [OpenAPI Spec](https://citedhealth.com/api/openapi.json) · [REST API Docs](https://citedhealth.com/developers/)

### Browse Health Conditions

Access 84 health conditions with descriptions, prevalence data, symptoms, and risk factors. Filter by featured status to find the most commonly researched conditions.

```ruby
client = CitedHealth::Client.new

# List all conditions
conditions = client.list_conditions
conditions.each { |c| puts "#{c.name}: #{c.description[0..80]}..." }

# Filter to featured conditions only
featured = client.list_conditions(is_featured: true)

# Get detailed condition information
hair_loss = client.get_condition("hair-loss")
puts hair_loss.name            # "Hair Loss"
puts hair_loss.prevalence      # Prevalence information
puts hair_loss.symptoms        # ["Thinning hair", ...]
puts hair_loss.risk_factors    # ["Genetics", "Stress", ...]
```

Learn more: [Health Conditions](https://citedhealth.com/conditions/) · [Hair Health](https://haircited.com) · [Sleep Health](https://sleepcited.com)

### Look Up Glossary Terms

Browse health and supplement terminology with 228 glossary terms covering abbreviations, definitions, and categorized entries.

```ruby
client = CitedHealth::Client.new

# List all glossary terms
terms = client.list_glossary
terms.each { |t| puts "#{t.term}: #{t.short_definition}" }

# Filter by category
supplement_terms = client.list_glossary(category: "supplements")

# Get a specific glossary term with full definition
term = client.get_glossary_term("bioavailability")
puts term.term              # "Bioavailability"
puts term.abbreviation      # Abbreviation if applicable
puts term.definition        # Full definition text
puts term.category          # Term category
```

Learn more: [Glossary](https://citedhealth.com/glossary/) · [Editorial Policy](https://citedhealth.com/editorial-policy/)

### Read Health Guides

Access curated guides on health topics and supplement usage, organized by category.

```ruby
client = CitedHealth::Client.new

# List all guides
guides = client.list_guides
guides.each { |g| puts "#{g.title} [#{g.category}]" }

# Filter by category
hair_guides = client.list_guides(category: "hair")

# Get a specific guide with full content
guide = client.get_guide("vitamin-d-hair-loss")
puts guide.title            # Guide title
puts guide.content          # Full guide content (Markdown)
puts guide.category         # Guide category
puts guide.meta_description # SEO description
```

Learn more: [Health Guides](https://citedhealth.com/guides/) · [Developer Docs](https://citedhealth.com/developers/)

## Error Handling

The client raises typed exceptions for common failure cases:

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

## Evidence Grades

CITED Health calculates evidence grades from peer-reviewed PubMed studies using study type, consistency, sample size, and study count:

| Grade | Label | Criteria |
|-------|-------|----------|
| A | Strong Evidence | Multiple RCTs/meta-analyses, consistent positive results |
| B | Good Evidence | At least one RCT, mostly consistent |
| C | Some Evidence | Small studies, some positive signals |
| D | Very Early Research | In vitro, case reports, pilot studies |
| F | Evidence Against | <30% of studies show positive effects |

## API Reference

All API responses are returned as typed Ruby objects with `attr_reader` accessors.

| Method | Description | Returns |
|--------|-------------|---------|
| `search_ingredients(query:, category:)` | Search ingredients by name or category | `Array<Ingredient>` |
| `get_ingredient(slug)` | Get ingredient by slug | `Ingredient` |
| `get_evidence(ingredient_slug:, condition_slug:)` | Get evidence for ingredient-condition pair | `EvidenceLink` |
| `get_evidence_by_id(id)` | Get evidence link by numeric ID | `EvidenceLink` |
| `search_papers(query:, year:)` | Search PubMed papers | `Array<Paper>` |
| `get_paper(pmid)` | Get paper by PubMed ID | `Paper` |
| `list_conditions(is_featured:)` | List health conditions | `Array<Condition>` |
| `get_condition(slug)` | Get condition by slug | `Condition` |
| `list_glossary(category:)` | List glossary terms | `Array<GlossaryTerm>` |
| `get_glossary_term(slug)` | Get glossary term by slug | `GlossaryTerm` |
| `list_guides(category:)` | List health guides | `Array<Guide>` |
| `get_guide(slug)` | Get guide by slug | `Guide` |

### Types

| Class | Fields |
|-------|--------|
| `Ingredient` | `id`, `name`, `slug`, `category`, `mechanism`, `recommended_dosage`, `forms`, `is_featured` |
| `Condition` | `slug`, `name`, `description`, `meta_description`, `prevalence`, `symptoms`, `risk_factors`, `is_featured` |
| `EvidenceLink` | `id`, `ingredient`, `condition`, `grade`, `grade_label`, `summary`, `direction`, `total_studies`, `total_participants` |
| `Paper` | `id`, `pmid`, `title`, `journal`, `publication_year`, `study_type`, `citation_count`, `is_open_access`, `pubmed_link` |
| `GlossaryTerm` | `slug`, `term`, `short_definition`, `definition`, `abbreviation`, `category` |
| `Guide` | `slug`, `title`, `content`, `category`, `meta_description` |

### Constructor Options

```ruby
# Default client
client = CitedHealth::Client.new

# Custom base URL and timeout
client = CitedHealth::Client.new(
  base_url: "https://citedhealth.com",
  timeout: 30
)
```

Full API documentation: [citedhealth.com/developers/](https://citedhealth.com/developers/)
OpenAPI 3.1.0 spec: [citedhealth.com/api/openapi.json](https://citedhealth.com/api/openapi.json)

## Learn More About Evidence-Based Supplements

- **Tools**: [Evidence Checker](https://citedhealth.com/api/evidence/) · [Ingredient Browser](https://citedhealth.com/) · [Paper Search](https://citedhealth.com/papers/)
- **Browse**: [Hair Health](https://haircited.com) · [Sleep Health](https://sleepcited.com) · [Gut Health](https://gutcited.com) · [Immune Health](https://immunecited.com) · [Brain Health](https://braincited.com)
- **Reference**: [Health Conditions](https://citedhealth.com/conditions/) · [Glossary](https://citedhealth.com/glossary/) · [Health Guides](https://citedhealth.com/guides/)
- **Guides**: [Grading Methodology](https://citedhealth.com/editorial-policy/) · [Medical Disclaimer](https://citedhealth.com/medical-disclaimer/)
- **API**: [REST API Docs](https://citedhealth.com/developers/) · [OpenAPI Spec](https://citedhealth.com/api/openapi.json)
- **Python**: [citedhealth on PyPI](https://pypi.org/project/citedhealth/)
- **TypeScript**: [citedhealth on npm](https://www.npmjs.com/package/citedhealth)
- **Go**: [citedhealth-go on pkg.go.dev](https://pkg.go.dev/github.com/citedhealth/citedhealth-go)
- **Rust**: [citedhealth on crates.io](https://crates.io/crates/citedhealth)

## Also Available

| Platform | Install | Link |
|----------|---------|------|
| **PyPI** | `pip install citedhealth` | [PyPI](https://pypi.org/project/citedhealth/) |
| **npm** | `npm install citedhealth` | [npm](https://www.npmjs.com/package/citedhealth) |
| **Go** | `go get github.com/citedhealth/citedhealth-go` | [pkg.go.dev](https://pkg.go.dev/github.com/citedhealth/citedhealth-go) |
| **Rust** | `cargo add citedhealth` | [crates.io](https://crates.io/crates/citedhealth) |
| **MCP** | `uvx citedhealth-mcp` | [PyPI](https://pypi.org/project/citedhealth-mcp/) |

## License

MIT — see [LICENSE](LICENSE) for details.
