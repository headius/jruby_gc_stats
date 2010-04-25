# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'jruby_gc_stats'
  s.version = "0.1"
  s.authors = ["Charles Oliver Nutter"]
  s.date = Time.now.strftime("YYYY-MM-DD")
  s.description = %q{A set of GC-monitoring methods for JRuby similar to those in Ruby Enterprise Edition}
  s.email = ["headius@headius.com"]
  s.extra_rdoc_files = ["README.txt"]
  s.files = Dir["{lib}/**/*"] + Dir["{*.txt}"]
  s.homepage = %q{http://github.com/headius/jruby_gc_stats}
  s.require_paths = ["lib"]
  s.summary = s.description
  s.platform = "java"
end
