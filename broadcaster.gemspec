# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'broadcaster'
  spec.version       = '1.0.2'
  spec.authors       = ['Gabriel Naiman']
  spec.email         = ['gabynaiman@gmail.com']
  spec.summary       = 'Broadcasting based on Redis PubSub'
  spec.description   = 'Broadcasting based on Redis PubSub'
  spec.homepage      = 'https://github.com/gabynaiman/broadcaster'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'redic',        '~> 1.5'
  spec.add_dependency 'class_config', '~> 0.0'

  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'minitest', '~> 5.0', '< 5.11'
  spec.add_development_dependency 'minitest-colorin', '~> 0.1'
  spec.add_development_dependency 'minitest-line', '~> 0.6'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'pry-nav', '~> 0.2'
end
