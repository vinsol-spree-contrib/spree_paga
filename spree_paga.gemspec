# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_paga'
  s.version     = '3.1.0'
  s.required_ruby_version = '>= 2.1.0'

  s.author    = 'Abhishek Jain'
  s.email     = 'info@vinsol.com'
  s.homepage  = 'http://vinsol.com'
  s.license   = "MIT"

  s.summary     = 'PAGA online payment for Spree'
  s.description = "Enable spree store to allow payment via PAGA Gateway (an online payment solution for Africa)."

  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '~> 3.1.0.beta'
  s.add_dependency 'delayed_job_active_record', '~> 4.0.0'
  s.add_dependency 'sass-rails'
  s.add_dependency 'coffee-rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
end
