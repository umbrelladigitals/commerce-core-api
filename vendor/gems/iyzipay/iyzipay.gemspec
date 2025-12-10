lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name                  = 'iyzipay'
  s.version               = '1.0.44'
  s.platform              = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.3'
  s.summary               = %q{iyzipay api ruby client}
  s.description           = %q{iyzipay api ruby client. You can sign up for an iyzico account at https://iyzico.com}
  s.authors               = ['Iyzico']
  s.email                 = 'iyzico-ci@iyzico.com'
  s.files                 = Dir['lib/**/*']
  s.test_files            = Dir['spec/**/*']
  s.homepage              = 'http://rubygems.org/gems/iyzipay'
  s.license               = 'MIT'

  s.add_runtime_dependency 'rest-client', '>= 1.8'
  s.add_development_dependency 'rspec', '~> 3.3.0'
  s.add_development_dependency 'rspec-rails', '~> 3.3.0'

  s.require_paths = ['lib']
end