# frozen_string_literal: true

require_relative "lib/timex_datalink_caldav/version"

Gem::Specification.new do |spec|
  spec.name = "timex_datalink_caldav"
  spec.version = TimexDatalinkCaldav::VERSION
  spec.authors = ["Willy Hardy"]
  spec.email = ["zpga8gbp@mailer.me"]

  spec.summary = "Allows the Timex Datalink watch to sync with a CalDAV server."
  spec.description = "Adds a CLI and a feature to pull your next day of calendar events into the Timex Datalink watch. Note: Hardcoded protocol1 and EST timezone. At the moment."
  spec.homepage = "https://github.com/wjhrdy/timex-datalink-caldav"
  spec.required_ruby_version = ">= 2.6.0"
  
  spec.license = "MIT"
  spec.metadata["github_repo"] = "ssh://github.com/wjhrdy/timex-datalink-caldav"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/wjhrdy/timex-datalink-caldav"
  spec.metadata["changelog_uri"] = "https://github.com/wjhrdy/timex-datalink-caldav/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.require_paths = ["lib"]
  spec.executables << 'timex_datalink_caldav'

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
