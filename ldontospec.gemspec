require 'rake'

Gem::Specification.new do |s|
  s.name = "ldontospec"
  s.version = "0.0.1"
  s.date = "2008-10-24"
  s.summary = "An ontology documentation generator based on the principles of Linked Data."
  s.email = "metade@gmail.com"
  s.homepage = "http://github.com/metade/ldontospec"
  s.description = "An ontology documentation generator based on the principles of Linked Data."
  s.has_rdoc = true
  s.authors = ['Patrick Sinclair']
  s.executables << 'ldontospec'
  s.files = FileList[
    "README", "Rakefile", "ldontospec.gemspec", "bin/*",
    'lib/**/*.rb', 'lib/ldontospec/templates/**/*', 'samples/**/*' ].to_a
  s.test_files = FileList["spec/*.rb"].to_a
  #s.rdoc_options = ["--main", "README.txt"]
  #s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.add_dependency("staticmatic")
  s.add_dependency("metade-activerdf_reddy")
  s.add_dependency("activerdf_rules")
end