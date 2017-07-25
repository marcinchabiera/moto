require 'thread'
require_relative 'test_generator'

module Moto
  module Runner
    # Thread safe provider of test instances
    class TestProvider

      # @param [Array] tests_metadata
      def initialize(tests_metadata)
        super()
        @test_repeats = Moto::Lib::Config.moto[:test_runner][:test_repeats]
        @current_test_repeat = 1
        @queue = Queue.new
        @tests_metadata = tests_metadata
        @test_generator = TestGenerator.new
      end

      # Use this to retrieve tests safely in multithreaded environment
      def get_test
        @queue.pop
      end

      # Pushes all tests requested to the queue
      def create_tests
        while @tests_metadata.count > 0 do
          test_metadata = @tests_metadata.shift

          if test_metadata
            test_variants = @test_generator.get_test_with_variants(test_metadata)
            test_variants.each do |test|
              for test_repeat in 1..@current_test_repeat
                @queue.push(test)
              end
            end
          end
        end
        @queue.length
      end

      # Number of threads waiting for a job
      def num_waiting
        @queue.num_waiting
      end

    end
  end
end

