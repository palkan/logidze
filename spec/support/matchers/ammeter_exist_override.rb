RSpec::Matchers.define :exist do |*expected|
  match do |file_path|
    if !(file_path.respond_to?(:exist?) || file_path.respond_to?(:exists?))
      File.exist?(file_path)
    else
      RSpec::Matchers::BuiltIn::Exist.new(*expected).matches?(file_path)
    end
  end
end
