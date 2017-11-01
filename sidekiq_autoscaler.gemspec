Gem::Specification.new do |spec|
  spec.name        = 'sidekiq_autoscaler'
  spec.version     = '0.3.0'
  spec.date        = '2017-11-01'
  spec.summary     = 'Generic Autoscaler algorithm focused on Sidekiq and Heroku'
  spec.description = 'A different approach on autoscaling rails on heroku.'
  spec.authors     = ['Oliver Kuster']
  spec.email       = 'olivervbk@gmail.com'
  spec.files       = Dir['{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  spec.homepage    = 'https://github.com/olivervbk/ruby-sidekiq-autoscaler'
  spec.license     = 'MIT'

  spec.add_development_dependency 'rake', '12.0.0'
  spec.add_development_dependency 'rspec', '3.5.0'
  spec.add_development_dependency 'rspec-collection_matchers', '1.1.3'

  spec.add_development_dependency 'sidekiq', '4.2.2'

  spec.add_development_dependency 'platform-api', '2.1.0'
end
