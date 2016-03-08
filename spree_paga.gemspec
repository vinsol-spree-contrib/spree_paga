# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_paga'
  s.version     = '1.0.0'
  s.required_ruby_version = '>= 1.9.3'

  s.author    = 'Abhishek Jain'
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'
  s.license   = "MIT"

  s.summary     = 'PAGA online payment for Spree'
  s.description = "Enable spree store to allow payment via PAGA Gateway (an online payment solution for Africa)."

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.0.0'
  s.add_dependency 'delayed_job_active_record', '~> 4.0.0'
  s.add_dependency 'sass-rails'
  s.add_dependency 'coffee-rails'
end
