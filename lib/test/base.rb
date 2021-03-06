require_relative 'status'

module Moto
  module Test
    class Base

      attr_reader   :name
      attr_reader   :env
      attr_reader   :params
      attr_accessor :static_path
      attr_accessor :evaled
      attr_accessor :status

      class << self
        attr_accessor :_path
      end

      def self.inherited(k)
        k._path = caller.first.match(/(.+):\d+:in/)[1]
      end

      def path
        self.class._path
      end

      # Initializes test to be executed with specified params and environment
      def init(params, params_index, global_index)
        @env = Moto::Lib::Config.environment
        @params = params
        @name = generate_name(params_index, global_index)

        @status = Moto::Test::Status.new
        @status.name = @name
        @status.test_class_name = self.class.name
        @status.env = Moto::Lib::Config.environment
        @status.params = @params
      end

      # Generates name of the test based on its properties:
      #  - number/name of currently executed configuration run
      #  - env
      def generate_name(params_index, global_index)
        simple_class_name = self.class.to_s.demodulize

        return "#{simple_class_name}_#{@env}_##{global_index}" if @params.empty?
        return "#{simple_class_name}_#{@env}_#{@params[:__name]}_#{global_index}" if @params.key?(:__name)
        return "#{simple_class_name}_#{@env}_P#{params_index}_#{global_index}" unless @params.key?(:__name)

        self.class.to_s
      end
      private :generate_name

      # Setter for :log_path
      def log_path=(param)
        @log_path = param

        # I hate myself for doing this, but I have no other idea for now how to pass log to Listeners that
        # make use of it (for example WebUI)
        @status.log_path = param
      end

      # @return [String] string with the path to the test's log
      def log_path
        @log_path
      end

      def dir
        return File.dirname(static_path) unless static_path.nil?
        File.dirname(self.path)
      end

      def filename
        return File.basename(static_path, '.*') unless static_path.nil?
        File.basename(path, '.*')
      end

      # Use this to run test
      # Initializes status, runs test, handles exceptions, finalizes status after run completion
      def run_test
        status.initialize_run

        begin
          run
        rescue Exception => exception
          status.log_exception(exception)
          raise
        ensure
          status.finalize_run
        end

      end

      # Only to be overwritten by final test execution
      # Use :run_test in order to run test
      def run
        # abstract
      end

      def before
        # abstract
      end

      def after
        # abstract
      end

      def skip(msg = nil)
        raise Exceptions::TestSkipped.new(msg.nil? ? 'Test skipped with no reason given.' : "Skip reason: #{msg}")
      end

      def fail(msg = nil)
        if msg.nil?
          msg = 'Test forcibly failed with no reason given.'
        else
          msg = "Forced failure, reason: #{msg}"
        end
        raise Exceptions::TestForcedFailure.new msg
      end

      def pass(msg = nil)
        if msg.nil?
          msg = 'Test forcibly passed with no reason given.'
        else
          msg = "Forced passed, reason: #{msg}"
        end
        raise Exceptions::TestForcedPassed.new msg
      end


      # Checks for equality of both arguments
      def assert_equal(a, b)
        assert(a == b, "Arguments should be equal: #{a} != #{b}.")
      end

      # Checks if passed value is equal to True
      def assert_true(value)
        assert(value, 'Logical condition not met, expecting true, given false.')
      end

      # Checks if passed value is equal to False
      def assert_false(value)
        assert(!value, 'Logical condition not met, expecting false, given true.')
      end

      # Checks if result of condition equals to True
      def assert(condition, message)
        if !condition
          if evaled
            # -1 because of added method header in generated class
            line_number = caller.select { |l| l.match(/\(eval\):\d*:in `run'/) }.first[/\d+/].to_i
          else
            line_number = caller.select { |l| l.match(/#{static_path}:\d*:in `run'/) }.first[/\d+/].to_i
          end

          status.log_failure("ASSERTION FAILED in line #{line_number}: #{message}")
          Thread.current['logger'].error(message)
        end
      end

      # Read a constants value from configuration files while taking the execution environment into the account.
      # @param [String] key Key to be searched for.
      # @return [String] Value of the key or nil if not found
      def const(key)
        Moto::Lib::Config.environment_const(key)
      end

      def client(name)
        Thread.current['clients_manager'].client(name)
      end

      def session
        client('Website').session
      end

    end
  end
end
