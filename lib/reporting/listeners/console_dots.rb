require_relative '../../runner/test_provider'

module Moto
  module Reporting
    module Listeners
      class ConsoleDots < Base

        def initialize(run_params)
          @chars_counter = 0
          @chars_line_max = config[:console_dots] ? config[:console_dots][:chars_line_max] : nil
          @chars_line_max = 50 if !@chars_line_max # default console dots chars line max
        end

        def end_run(run_status)
          puts ''
          puts ''
          puts "FINISHED: #{run_status.to_s}, duration: #{Time.at(run_status.duration).utc.strftime("%H:%M:%S")}"
          puts "Tests executed: #{run_status.tests_all.length}"
          puts "  Passed:       #{run_status.tests_passed.length}"
          puts "  Failure:      #{run_status.tests_failed.length}"
          puts "  Error:        #{run_status.tests_error.length}"
          puts "  Skipped:      #{run_status.tests_skipped.length}"

          if run_status.tests_failed.length > 0
            puts ''
            puts 'FAILURES: '
            run_status.tests_failed.each do |test_status|
              puts test_status.display_name
              puts "\t" + test_status.results.last.failures.join("\n\t")
              puts ''
            end
          end

          if run_status.tests_error.length > 0
            puts ''
            puts 'ERRORS: '
            run_status.tests_error.each do |test_status|
              puts test_status.display_name
              puts "\t" + test_status.results.last.message
              puts ''
            end
          end

          if run_status.tests_skipped.length > 0
            puts ''
            puts 'SKIPPED: '
            run_status.tests_skipped.each do |test_status|
              puts test_status.display_name
              puts "\t" + test_status.results.last.message
              puts ''
            end
          end

        end

        def end_test(test_status)
          result = case test_status.results.last.code
                     when Moto::Test::Result::PASSED then
                       '.'
                     when Moto::Test::Result::FAILURE then
                       'F'
                     when Moto::Test::Result::ERROR then
                       'E'
                     when Moto::Test::Result::SKIPPED then
                       's'
                   end

          print result
          @chars_counter += 1
          @tests_total = Moto::Lib::Config.moto[:test_runner][:tests_total]
          if @chars_line_max
            puts " [#{@chars_counter}/#{@tests_total}]" if (@chars_counter % @chars_line_max) == 0 || @chars_counter == @tests_total
          end
          STDOUT.flush

        end

        # @return [Hash] Hash with config for ConsolDots
        def config
          Moto::Lib::Config.moto[:test_reporter][:listeners]
        end

        private :config

      end
    end
  end
end