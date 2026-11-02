require "coverage"
require "fileutils"
require "json"

Coverage.start(lines: true)

at_exit do
  output_directory = ENV.fetch("COVERAGE_OUTPUT_DIR")
  FileUtils.mkdir_p(output_directory)
  output_path = File.join(output_directory, "ruby-coverage-#{Process.pid}.json")
  File.write(output_path, JSON.generate(Coverage.result))
end
