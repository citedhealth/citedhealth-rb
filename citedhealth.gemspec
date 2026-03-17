# frozen_string_literal: true

require_relative "lib/citedhealth/version"

Gem::Specification.new do |s|
  s.name        = "citedhealth"
  s.version     = CitedHealth::VERSION
  s.summary     = "Ruby client for the Cited Health evidence-based supplement API"
  s.description = "API client for citedhealth.com. Search ingredients, evidence links, and research papers for evidence-based health supplement information. Zero dependencies."
  s.authors     = ["Cited Health"]
  s.email       = ["hello@citedhealth.com"]
  s.homepage    = "https://citedhealth.com"
  s.license     = "MIT"
  s.required_ruby_version = ">= 3.0"

  s.bindir      = "exe"
  s.executables = ["citedhealth"]
  s.files       = Dir["lib/**/*.rb"] + Dir["exe/*"]

  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "webmock", "~> 3.0"

  s.metadata = {
    "homepage_uri"      => "https://citedhealth.com",
    "source_code_uri"   => "https://github.com/citedhealth/citedhealth-rb",
    "changelog_uri"     => "https://github.com/citedhealth/citedhealth-rb/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://citedhealth.com/developers/",
    "bug_tracker_uri"   => "https://github.com/citedhealth/citedhealth-rb/issues",
  }
end
