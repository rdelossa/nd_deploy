# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nd_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "nd_deploy"
  spec.version       = NdDeploy::VERSION
  spec.authors       = ["Richard de los Santos"]
  spec.email         = ["rdelossa@nd.edu"]
  spec.summary       = "Provide nd deploy files to apps"
  spec.description   = "This gem provides nd deploy capabilities to apps"
  spec.homepage      = "http://registrar.nd.edu"
  spec.license       = "MIT"

  spec.files = Dir['Rakefile', '{bin,lib,man,test,spec}/**/**/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"

  spec.add_dependency 'capistrano'
  spec.add_dependency 'capistrano-rvm'

end
