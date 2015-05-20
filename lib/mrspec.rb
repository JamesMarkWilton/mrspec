# presumably this is loose enough to not whine all the time, but tight enough to not break
gem 'rspec',    '~> 3.0'
gem 'minitest', '~> 5.0'

require 'rspec/core'
require 'minitest'

class << Minitest::Runnable
  # adds metadata to the class
  def classmeta(metadata)
    class_metadata.merge! metadata
  end

  def class_metadata
    @selfmetadata ||= {}
  end

  # adds metadata to the next test defined
  def meta(metadata)
    pending_metadata.merge! metadata
  end

  # the tests' metadata
  def example_metadata
    @metadata ||= Hash.new { |metadata, mname| metadata[mname] = {} }
  end

  private

  def method_added(manme)
    example_metadata[manme.intern].merge! pending_metadata
    pending_metadata.clear
  end

  def pending_metadata
    @pending_metadata ||= {}
  end
end


module MRspec
  def self.group_name(klass)
    klass.inspect.sub /Test$/, ''
  end

  def self.example_name(method_name)
    method_name.to_s.sub(/^test_/, '').tr('_', ' ')
  end

  def self.import_minitest
    Minitest.reporter = Minitest::CompositeReporter.new # we're not using the reporter, but some plugins, (eg minitest/pride) expect it to be there
    Minitest.load_plugins
    Minitest.init_plugins Minitest.process_args([])

    Minitest::Runnable.runnables.each { |klass| wrap_class klass }
  end

  def self.wrap_class(klass)
    example_group = RSpec.describe group_name(klass), klass.class_metadata
    klass.runnable_methods.each do |method_name|
      wrap_test example_group, klass, method_name
    end
  end

  def self.wrap_test(example_group, klass, mname)
    metadata = klass.example_metadata[mname.intern]
    example = example_group.example example_name(mname), metadata do
      instance = Minitest.run_one_method klass, mname
      instance.passed?  and next
      instance.skipped? and pending 'skipped'
      raise instance.failure
    end

    fix_metadata example.metadata, klass.instance_method(mname)
  end

  def self.fix_metadata(metadata, method)
    file, line = method.source_location
    return unless file && line # not sure when this wouldn't be true, so no tests on it, but hypothetically it could happen
    metadata[:file_path]          = file
    metadata[:line_number]        = line
    metadata[:location]           = "#{file}:#{line}"
    metadata[:absolute_file_path] = File.expand_path(file)
  end
end


class MRspec::Runner < RSpec::Core::Runner
  def initialize(*)
    super
    # seems like there should be a better way, but I can't figure out what it is
    files_and_dirs = @options.options[:files_or_directories_to_run]
    files_and_dirs << 'spec' << 'test' if files_and_dirs.empty?
  end
end


class MRspec::Configuration < RSpec::Core::Configuration
  def load_spec_files(*)
    super                  # will load the files
    MRspec.import_minitest # declare them to RSpec
  end
end


RSpec.configuration = MRspec::Configuration.new

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_gems_from_backtrace 'minitest'
  config.backtrace_exclusion_patterns << /mrspec\.rb$/
  config.pattern = config.pattern.sub('_spec.rb', '_{spec,test}.rb') # look for files suffixed with both _spec and _test
end


