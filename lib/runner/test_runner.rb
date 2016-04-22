require_relative '../reporting/test_reporter'
require_relative './test_provider'

module Moto
  module Runner
    class TestRunner

      attr_reader :logger
      attr_reader :config
      attr_reader :test_reporter

      def initialize(test_paths_absolute, environments, config, test_reporter)
        @test_paths_absolute = test_paths_absolute
        @config = config
        @test_reporter = test_reporter

        # TODO: initialize logger from config (yml or just ruby code)
        @logger = Logger.new(File.open("#{MotoApp::DIR}/moto.log", File::WRONLY | File::APPEND | File::CREAT))

        @environments = environments.empty? ? environments << :__default : environments
      end

      def run
        test_provider = TestProvider.new(@test_paths_absolute, @environments, @config[:moto][:test_runner][:test_repeats])
        threads_max = @config[:moto][:test_runner][:thread_count] || 1

        # remove log/screenshot files from previous execution
        @test_paths_absolute.each do |test_path|
          FileUtils.rm_rf("#{File.dirname(test_path)}/logs")
        end

        @test_reporter.report_start_run

        # Create as many threads as we're allowed by the config file.
        # test_provider.get_test - will invoke Queue.pop thus putting the thread to sleep
        # once there is no more work.
        (1..threads_max).each do |index|
          Thread.new do
            Thread.current[:id] = index
            loop do
              tc = ThreadContext.new(@config, test_provider.get_test, @test_reporter)
              tc.run
            end
          end
        end

        # Waiting for all threads to run out of work so we can end the application
        loop do
          if test_provider.num_waiting == threads_max
            break
          end

          sleep 1
        end

        @test_reporter.report_end_run
      end

    end
  end
end