require 'optparse'
require 'yaml'

require_relative '../lib/cli'
require_relative '../lib/app_generator'
require_relative '../lib/config'
module Moto

  class Parser

    def self.run(argv)
      begin

        if argv[0] == '--version'
          puts Moto::VERSION
        elsif argv[0] == 'run' && argv.length > 1
          Moto::Cli.run(run_parse(argv))
        elsif argv[0] == 'generate' && argv.length > 1
          Moto::AppGenerator.run(generate_parse(argv))
        else
          show_help
        end
      rescue SystemExit => e
        Kernel.exit(e.status)
      rescue Exception => e
        puts e.message + "\n\n"
        puts e.backtrace.join("\n")
      end
    end

    def self.run_parse(argv)
      require 'bundler/setup'
      Bundler.require

      # Default options
      options = {}
      options[:listeners] = []
      options[:name] = ''

      # Parse arguments
      OptionParser.new do |opts|
        opts.on('-t', '--tests Tests', Array)              { |v| options[:tests]        = v }
        opts.on('-g', '--tags Tags', Array)                { |v| options[:tags]         = v }
        opts.on('-f', '--filters Filters', Array)          { |v| options[:filters]      = v }
        opts.on('-l', '--listeners Listeners', Array)      { |v| options[:listeners]    = v }
        opts.on('-e', '--environment Environment')         { |v| options[:environment]  = v }
        opts.on('-n', '--name Name')                       { |v| options[:name]         = v }
        opts.on('-c', '--config Config')                   { |v| options[:config_name]  = v }
      end.parse!

      if options[:name].empty?
        options[:name] = evaluate_name(options[:tags], options[:tests], options[:filters])
      end

      if options[:environment]
        Moto::Lib::Config.environment = options[:environment]
        Moto::Lib::Config.load_configuration(options[:config_name] ? options[:config_name] : 'moto')
      else
        puts 'ERROR: Environment is mandatory.'
        Kernel.exit(-1)
      end

      return options
    end

    # Generate default name based on input parameters
    def self.evaluate_name(tests, tags, filters)
      name = ''

      if tests
        name << "Tests: #{tests.join(',')}  "
      end

      if tags
        name << "Tags: #{tags.join(',')}  "
      end

      if filters
        name << "Filters: #{filters.join(',')}  "
      end

      return name
    end

    # Parses attributes passed to the application when run by 'moto generate'
    def self.generate_parse(argv)
      options = {}

      OptionParser.new do |opts|
        opts.on('-t', '--test Test') { |v| options[:dir ] = v }
        opts.on('-a', '--appname AppName') { |v| options[:app_name ] = v }
        opts.on('-b', '--baseclass BaseClass') { |v| options[:base_class] = v }
        opts.on('-f', '--force') { options[:force ] = true }
      end.parse!

      options[:dir] = options[:dir].underscore

      if options[:app_name].nil?
        options[:app_name] = 'MotoApp'
      end

      return options
    end

    def self.show_help
      puts """
      Moto (#{Moto::VERSION}) CLI Help:
      moto --version Display current version

      moto run:      
       -t, --tests       Tests to be executed.
       -g, --tags        Tags of tests to be executed.
                         Use # MOTO_TAGS: TAGNAME in test to assign tag.
       -f, --filters     Tags that filter tests passed via -t parameter.
                         Only tests in appropriate directory, having appropriate tag will be executed.
                         Use # MOTO_TAGS: TAGNAME in test to assign tag.
       -l, --listeners   Reporters to be used.
                         Defaults are Moto::Reporting::Listeners::ConsoleDots, Moto::Reporting::Listeners::JunitXml
                         One reporter that is always used: Moto::Reporting::Listeners::KernelCode
       -e, --environment Mandatory environment. Environment constants and tests parametrized in certain way depend on this.
       -c, --config      Name of the config, without extension, to be loaded from MotoApp/config/CONFIG_NAME.rb
                         Default: moto (which loads: MotoApp/config/moto.rb)


      moto generate:
       -t, --test        Path and name of the test to be created.
                         Examples:
                         -ttest_name          will create MotoApp/tests/test_name/test_name.rb
                         -tdir/test_name      will create MotoApp/tests/dir/test_name/test_name.rb
       -a, --appname     Name of the application. Will be also used as topmost module in test file.
                         Default: MotoApp
       -b, --baseclass   File, without extension, with base class from which test will derive. Assumes one class per file.
                         Examples:
                         -btest_base          will use the file in MotoApp/lib/test/test_base.rb
                         -bsubdir/test_base   will use the file in MotoApp/lib/test/subdir/test_base.rb
                         By default class will derive from Moto::Test
       -f, --force       Forces generator to overwrite previously existing class file in specified location.
                         You have been warned.
      """
    end

  end
end
