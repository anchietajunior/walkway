#!/usr/bin/env ruby
require "json"
require "open3"

SOURCE_EXTENSIONS = %w[.rb .js .jsx .mjs .cjs .ts .tsx].freeze
TEST_PATH_PATTERN = %r{(\A|/)(test|spec|__tests__)/|_test\.rb\z|_spec\.rb\z|\.(test|spec)\.[cm]?[jt]sx?\z}

def run_git(*arguments)
  output, status = Open3.capture2("git", *arguments)
  abort "git #{arguments.join(" ")} failed" unless status.success?
  output.force_encoding(Encoding::UTF_8).scrub
end

def changed_lines_by_file(base_commit)
  changed_lines = {}
  current_path = nil

  run_git("diff", "--unified=0", "--no-color", base_commit, "HEAD").each_line do |diff_line|
    if diff_line.start_with?("+++ ")
      current_path = diff_line.start_with?("+++ b/") ? diff_line.delete_prefix("+++ b/").chomp : nil
      next
    end

    hunk_header = diff_line.match(/\A@@ -\S+ \+(\d+)(?:,(\d+))? @@/)
    next unless current_path && hunk_header

    first_line = Integer(hunk_header[1])
    line_count = hunk_header[2] ? Integer(hunk_header[2]) : 1
    changed_lines[current_path] ||= []
    changed_lines[current_path].concat((first_line...(first_line + line_count)).to_a)
  end

  changed_lines
end

def source_file?(path)
  SOURCE_EXTENSIONS.include?(File.extname(path)) && !path.match?(TEST_PATH_PATTERN)
end

def json_file_entries(coverage)
  simplecov_suites = coverage.values.select { |value| value.is_a?(Hash) && value.key?("coverage") }
  return coverage if simplecov_suites.empty?

  file_entries = {}
  simplecov_suites.each { |suite| file_entries.merge!(suite["coverage"]) }
  file_entries
end

def read_json_coverage(coverage)
  line_hits_by_source = {}

  json_file_entries(coverage).each do |source_path, entry|
    line_counts = entry.is_a?(Hash) ? entry["lines"] : entry
    next unless line_counts

    line_hits = {}
    line_counts.each_with_index do |hits, index|
      line_hits[index + 1] = hits unless hits.nil?
    end
    line_hits_by_source[source_path] = line_hits
  end

  line_hits_by_source
end

def read_lcov_coverage(lcov_text)
  line_hits_by_source = {}
  current_source = nil

  lcov_text.each_line do |lcov_line|
    record = lcov_line.chomp

    if record.start_with?("SF:")
      current_source = record.delete_prefix("SF:")
      line_hits_by_source[current_source] ||= {}
    elsif record.start_with?("DA:") && current_source
      line_number_text, hits_text = record.delete_prefix("DA:").split(",")
      line_hits_by_source[current_source][Integer(line_number_text)] = Integer(hits_text)
    elsif record == "end_of_record"
      current_source = nil
    end
  end

  line_hits_by_source
end

def read_coverage_file(coverage_path)
  coverage_text = File.read(coverage_path, encoding: Encoding::UTF_8).scrub
  return read_json_coverage(JSON.parse(coverage_text)) if File.extname(coverage_path) == ".json"

  read_lcov_coverage(coverage_text)
end

def path_in_repository(source_path, repository_root)
  absolute_path = File.expand_path(source_path, repository_root)
  absolute_path = File.realpath(absolute_path) if File.exist?(absolute_path)
  return nil unless absolute_path.start_with?("#{repository_root}/")

  absolute_path.delete_prefix("#{repository_root}/")
end

def line_hits_by_file(coverage_paths, repository_root)
  merged_hits = {}

  coverage_paths.each do |coverage_path|
    read_coverage_file(coverage_path).each do |source_path, line_hits|
      relative_path = path_in_repository(source_path, repository_root)
      next unless relative_path

      merged_hits[relative_path] ||= {}
      line_hits.each do |line_number, hits|
        previous_hits = merged_hits[relative_path].fetch(line_number, 0)
        merged_hits[relative_path][line_number] = [previous_hits, hits].max
      end
    end
  end

  merged_hits
end

def line_ranges_text(line_numbers)
  ranges = []

  line_numbers.sort.each do |line_number|
    last_range = ranges.last
    if last_range && last_range[:last] == line_number - 1
      last_range[:last] = line_number
    else
      ranges << { first: line_number, last: line_number }
    end
  end

  range_texts = ranges.map do |range|
    range[:first] == range[:last] ? range[:first].to_s : "#{range[:first]}-#{range[:last]}"
  end
  range_texts.join(", ")
end

def report_changed_lines_coverage(base_commit, coverage_paths)
  repository_root = File.realpath(run_git("rev-parse", "--show-toplevel").chomp)
  hits_by_file = line_hits_by_file(coverage_paths, repository_root)
  covered_total = 0
  executable_total = 0
  files_not_loaded = []

  changed_lines_by_file(base_commit).sort.each do |path, changed_lines|
    next unless source_file?(path) && changed_lines.any?

    unless hits_by_file.key?(path)
      files_not_loaded << path
      next
    end

    line_hits = hits_by_file[path]
    executable_lines = changed_lines.select { |line_number| line_hits.key?(line_number) }
    next if executable_lines.empty?

    uncovered_lines = executable_lines.select { |line_number| line_hits[line_number].zero? }
    covered_count = executable_lines.size - uncovered_lines.size
    covered_total += covered_count
    executable_total += executable_lines.size

    file_summary = "#{path}: #{covered_count}/#{executable_lines.size} changed executable lines covered"
    file_summary += "; uncovered: #{line_ranges_text(uncovered_lines)}" if uncovered_lines.any?
    puts file_summary
  end

  files_not_loaded.each { |path| puts "Not loaded by the tests: #{path}" }

  if executable_total.zero?
    puts "Total: no changed executable lines"
  else
    percentage = (100.0 * covered_total / executable_total).round(1)
    puts "Total: #{covered_total}/#{executable_total} changed executable lines covered (#{percentage}%)"
  end
end

if $PROGRAM_NAME == __FILE__
  base_commit, *coverage_paths = ARGV
  abort "Usage: changed_lines_coverage.rb <base commit> <coverage file>..." if base_commit.nil? || coverage_paths.empty?

  report_changed_lines_coverage(base_commit, coverage_paths)
end
