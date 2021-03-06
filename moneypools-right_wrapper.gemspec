# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{moneypools-right_wrapper}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Zachary Belzer"]
  s.date = %q{2010-03-19}
  s.description = %q{Simple wrapper over the right_aws utility providing verbose output and synchronization}
  s.email = %q{zbelzer@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "lib/right_wrapper.rb",
     "moneypools-right_wrapper.gemspec"
  ]
  s.homepage = %q{http://github.com/moneypools/right_wrapper}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Simple wrapper over the right_aws utility providing verbose output and synchronization}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redaranj-right_aws>, [">= 1.11.0"])
    else
      s.add_dependency(%q<redaranj-right_aws>, [">= 1.11.0"])
    end
  else
    s.add_dependency(%q<redaranj-right_aws>, [">= 1.11.0"])
  end
end

