require 'capybara'

module Moto
  module Clients

  	class Website < Moto::Clients::Base

      attr_reader :session

      ignore_logging(:page)
      ignore_logging(:context)
      ignore_logging(:session)

      def init
        if context.runner.my_config[:grid][:capabilities] == nil
          capabilities = Selenium::WebDriver::Remote::Capabilities.firefox
        else
          capabilities = Selenium::WebDriver::Remote::Capabilities.new(context.runner.my_config[:grid][:capabilities])
        end
        Capybara.register_driver :grid do |app|
          Capybara::Selenium::Driver.new(app,
                                        :browser => :remote,
                                        :url => context.runner.my_config[:grid][:url],
                                        :desired_capabilities => capabilities)
        end
      end

      def start_run
        # TODO: make session driver configurable
        context.runner.my_config[:capybara][:default_selector] &&
            Capybara.default_selector = context.runner.my_config[:capybara][:default_selector]
        @session = Capybara::Session.new(context.runner.my_config[:capybara][:default_driver])
        @pages = {}
      end

      def end_run
        @session.driver.quit
      end

      def start_test(test)
        # @context.current_test.logger.info("Hi mom, I'm opening some pages!")
        @session.reset_session!
      end

      def end_test(test)
        @session.reset_session!
      end

  		def page(p)
  		  page_class_name = "#{self.class.name}::Pages::#{p}"
  		  page_class_name.gsub!('Moto::', 'MotoApp::')
  		  if @pages[page_class_name].nil?
          a = page_class_name.underscore.split('/')
          page_path = a[1..20].join('/')
          require "#{MotoApp::DIR}/lib/#{page_path}"
  		    @pages[page_class_name] = page_class_name.constantize.new(self)
  		  end
  		  @pages[page_class_name]
  		end

  	end
  end
end
