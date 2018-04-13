Gem::Specification.new do |s|
	s.name			= 'bloc_record'
	s.version		= '0.0.0'
	s.date			= '2018-04-01'
	s.summary		= 'BlocRecord ORM'
	s.description	= 'An ActiveRecord-esque ORM adaptor'
	s.authors		= ['Yuriy Ivanov']
	s.email			= 'ymivanov@icloud.com'
	s.files			= Dir['lib/**/*.rb']
	s.require_paths = ["lib"]
	s.homepage		=	
		'http://rubygems.org/gems/bloc_record'
	s.license		= 'MIT'
	s.add_runtime_dependency	'sqlite3', '~> 1.3'
end