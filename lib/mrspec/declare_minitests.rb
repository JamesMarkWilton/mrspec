require 'minitest'
require 'mrspec/minitest_assertion_for_rspec'

module MRspec
  module DeclareMinitests
    extend self

    def self.call
      init_minitest
      wrap_classes Minitest::Runnable.runnables
    end

    def group_name(klass)
      klass.name.sub(/^Test/, '').sub(/Test$/, '')
    end

    def example_name(method_name)
      # remove test_, and turn underscores into spaces
      #   https://github.com/seattlerb/minitest/blob/f1081566ec6e9e391628bde3a26fb057ad2576a8/lib/minitest/test.rb#L62
      # remove test_0001_, where the number increments
      #   https://github.com/seattlerb/minitest/blob/f1081566ec6e9e391628bde3a26fb057ad2576a8/lib/minitest/spec.rb#L218-222
      method_name.sub(/^test_(?:\d{4}_)?/, '').tr('_', ' ')
    end

    def init_minitest
      Minitest.reporter = Minitest::CompositeReporter.new # we're not using the reporter, but some plugins, (eg minitest/pride) expect it to be there
      Minitest.load_plugins
      Minitest.init_plugins Minitest.process_args([])
    end

    def wrap_classes(klasses)
      klasses.each { |klass| wrap_class klass }
    end

    def wrap_class(klass)
      example_group = RSpec.describe group_name(klass), klass.class_metadata
      klass.runnable_methods.each do |method_name|
        wrap_test example_group, klass, method_name
      end
    end

    def wrap_test(example_group, klass, mname)
      metadata = klass.example_metadata[mname.intern]
      example = example_group.example example_name(mname), metadata do
        instance = Minitest.run_one_method klass, mname
        next              if instance.passed?
        pending 'skipped' if instance.skipped?
        error = instance.failure.error
        raise error unless error.kind_of? Minitest::Assertion
        raise MinitestAssertionForRSpec.new error
      end
      fix_metadata example.metadata, klass.instance_method(mname)
    end

    def fix_metadata(metadata, method)
      file, line = method.source_location
      return unless file && line # not sure when this wouldn't be true, so no tests on it, but hypothetically it could happen
      metadata[:file_path]          = file
      metadata[:line_number]        = line
      metadata[:location]           = "#{file}:#{line}"
      metadata[:absolute_file_path] = File.expand_path(file)
    end
  end
end
