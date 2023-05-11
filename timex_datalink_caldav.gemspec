# frozen_string_literal: true

require_relative "lib/timex_datalink_caldav/version"

Gem::Specification.new do |spec|
  spec.name = "timex_datalink_caldav"
  spec.version = timex_datalink_caldav::VERSION
  spec.authors = ["Willy Hardy"]
  spec.email = ["timexcaldav@msg.ooo"]

  spec.summary = "This uses a CalDAV server to sync a Timex Datalink watch."
  spec.description = "This uses a CalDAV server to sync a Timex Datalink watch."
  spec.homepage = "https://github.com/wjhrdy/timex_datalink_caldav"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wjhrdy/timex_datalink_caldav"
  spec.metadata["changelog_uri"] = "https://github.com/wjhrdy/timex_datalink_caldav/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
