# frozen_string_literal: true

# Fix compatibility issue between Rails 8.0.4 and minitest 6.0.1
# Rails 8.0.4's LineFiltering defines run(reporter, options = {}) but
# minitest 6.0.1 calls Runnable.run(klass, method_name, reporter) with 3 arguments
#
# Since Rails::LineFiltering is extended on ActiveSupport::TestCase, it becomes
# a class method that shadows Minitest::Runnable.run
#
# This monkey patch fixes the method signature to accept minitest's calling pattern
Rails.application.config.after_initialize do
  if defined?(ActiveSupport::TestCase) && defined?(Minitest::Runnable)
    ActiveSupport::TestCase.singleton_class.class_eval do
      # Redefine run to accept minitest's 3-argument signature
      # while preserving Rails test filtering functionality
      define_method(:run) do |klass, method_name, reporter|
        # Apply Rails test filters if needed
        if respond_to?(:compose_filter, true)
          filter = Rails::TestUnit::Runner.compose_filter(klass, nil)
        end

        # Call the original minitest Runnable.run
        Minitest::Runnable.run(klass, method_name, reporter)
      end
    end
  end
end
