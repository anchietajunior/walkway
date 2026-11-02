require "minitest/autorun"
require "json"
require "open3"
require "tmpdir"
require "fileutils"

class ChangedLinesCoverageTest < Minitest::Test
  SCRIPT_PATH = File.expand_path("changed_lines_coverage.rb", __dir__)

  def test_reports_covered_uncovered_and_not_loaded_changed_lines
    Dir.mktmpdir do |repository|
      Dir.chdir(repository) do
        git("init", "--quiet")
        write_file("app/models/order.rb", "class Order\n  def total\n  end\nend\n")
        write_file("app/models/invoice.rb", "class Invoice\nend\n")
        write_file("app/javascript/cart.ts", "export const empty = [];\n")
        commit("base")
        base_commit = git("rev-parse", "HEAD").chomp

        write_file("app/models/order.rb", "class Order\n  def total\n    paid = true\n    return 0 unless paid\n  end\nend\n")
        write_file("app/models/invoice.rb", "class Invoice\n  def due; end\nend\n")
        write_file("app/javascript/cart.ts", "export const empty = [];\nexport const count = (items) => items.length;\n")
        write_file("test/models/order_test.rb", "class OrderTest\nend\n")
        write_file("DOMAIN.md", "Ação do cliente\n")
        commit("change")

        ruby_coverage_path = File.join(repository, "ruby-coverage.json")
        File.write(ruby_coverage_path, JSON.generate(
          "#{repository}/app/models/order.rb" => { "lines" => [1, 1, 1, 0, nil, nil] }
        ))
        lcov_path = File.join(repository, "lcov.info")
        File.write(lcov_path, "SF:app/javascript/cart.ts\nDA:1,1\nDA:2,3\nend_of_record\n")

        ascii_locale = { "LANG" => "C", "LC_ALL" => "C" }
        output, status = Open3.capture2(ascii_locale, "ruby", SCRIPT_PATH, base_commit, ruby_coverage_path, lcov_path)

        assert status.success?, output
        assert_includes output, "app/models/order.rb: 1/2 changed executable lines covered; uncovered: 4"
        assert_includes output, "app/javascript/cart.ts: 1/1 changed executable lines covered"
        assert_includes output, "Not loaded by the tests: app/models/invoice.rb"
        assert_includes output, "Total: 2/3 changed executable lines covered (66.7%)"
        refute_includes output, "order_test.rb"
      end
    end
  end

  private

  def git(*arguments)
    output, status = Open3.capture2("git", "-c", "user.name=Test", "-c", "user.email=test@example.com", *arguments)
    raise "git #{arguments.join(" ")} failed" unless status.success?

    output
  end

  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def commit(message)
    git("add", "--all")
    git("commit", "--quiet", "--message", message)
  end
end
