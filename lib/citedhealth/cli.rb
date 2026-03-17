# frozen_string_literal: true

require "optparse"
require "json"

module CitedHealth
  # Command-line interface for the Cited Health API.
  #
  # Provides 5 subcommands to search ingredients, evidence, and papers
  # from the terminal. Zero runtime dependencies beyond Ruby stdlib.
  #
  #   citedhealth ingredients biotin
  #   citedhealth ingredient vitamin-d
  #   citedhealth evidence biotin hair-loss
  #   citedhealth papers --year 2024
  #   citedhealth paper 12345678
  #
  module CLI
    USAGE = <<~HELP
      Usage: citedhealth <command> [options]

      Commands:
        ingredients [QUERY] [-c CATEGORY]   Search ingredients
        ingredient SLUG                     Get ingredient details
        evidence INGREDIENT CONDITION       Get evidence for a pair
        papers [QUERY] [-y YEAR]            Search research papers
        paper PMID                          Get paper by PubMed ID

      Options:
        --json       Compact JSON output
        --version    Show version
        --help       Show this help
    HELP

    class << self
      def run(argv)
        args = argv.dup
        compact = extract_flag!(args, "--json")

        if extract_flag!(args, "--version")
          puts "citedhealth #{CitedHealth::VERSION}"
          return
        end

        if args.empty? || extract_flag!(args, "--help")
          puts USAGE
          return
        end

        command = args.shift
        client = CitedHealth::Client.new

        result = case command
                 when "ingredients" then cmd_ingredients(client, args)
                 when "ingredient"  then cmd_ingredient(client, args)
                 when "evidence"    then cmd_evidence(client, args)
                 when "papers"      then cmd_papers(client, args)
                 when "paper"       then cmd_paper(client, args)
                 else
                   warn "Unknown command: #{command}"
                   warn USAGE
                   exit 1
                 end

        output(result, compact: compact)
      rescue CitedHealth::NotFoundError => e
        warn "Error: #{e.message}"
        exit 1
      rescue CitedHealth::RateLimitError => e
        msg = "Error: Rate limit exceeded"
        msg += " (retry after #{e.retry_after}s)" if e.retry_after
        warn msg
        exit 1
      rescue CitedHealth::Error => e
        warn "Error: #{e.message}"
        exit 1
      end

      private

      def extract_flag!(args, flag)
        if args.include?(flag)
          args.delete(flag)
          true
        else
          false
        end
      end

      def cmd_ingredients(client, args)
        category = extract_option!(args, "-c")
        query = args.join(" ")
        results = client.search_ingredients(query: query, category: category || "")
        results.map { |i| to_hash(i) }
      end

      def cmd_ingredient(client, args)
        slug = args.shift
        if slug.nil? || slug.empty?
          warn "Usage: citedhealth ingredient SLUG"
          exit 1
        end
        to_hash(client.get_ingredient(slug))
      end

      def cmd_evidence(client, args)
        ingredient_slug = args.shift
        condition_slug = args.shift
        if ingredient_slug.nil? || condition_slug.nil?
          warn "Usage: citedhealth evidence INGREDIENT CONDITION"
          exit 1
        end
        to_hash(client.get_evidence(
          ingredient_slug: ingredient_slug,
          condition_slug: condition_slug
        ))
      end

      def cmd_papers(client, args)
        year_str = extract_option!(args, "-y")
        year = year_str&.to_i
        query = args.join(" ")
        results = client.search_papers(query: query, year: year)
        results.map { |p| to_hash(p) }
      end

      def cmd_paper(client, args)
        pmid = args.shift
        if pmid.nil? || pmid.empty?
          warn "Usage: citedhealth paper PMID"
          exit 1
        end
        to_hash(client.get_paper(pmid))
      end

      def extract_option!(args, flag)
        idx = args.index(flag)
        return nil unless idx

        args.delete_at(idx) # remove flag
        args.delete_at(idx) # remove value
      end

      def to_hash(obj)
        hash = {}
        obj.instance_variables.each do |var|
          key = var.to_s.delete_prefix("@")
          value = obj.instance_variable_get(var)
          hash[key] = case value
                      when CitedHealth::NestedIngredient, CitedHealth::Condition
                        to_hash(value)
                      else
                        value
                      end
        end
        hash
      end

      def output(data, compact:)
        if compact
          puts JSON.generate(data)
        else
          puts JSON.pretty_generate(data)
        end
      end
    end
  end
end
