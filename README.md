# organization_gem_dependencies

Figure out where your gems are actually being used!

This gem installs a command line utility `organization_gem_dependencies`, that
outputs a json file with a reverse dependency tree.

## Installation

```sh
gem install organization_gem_dependencies
```

## Usage

```sh
organization_gem_dependencies GITHUB_ORGANIZATION [--direct] [--gems GEM1,GEM2,GEM3]
```

You will be securely prompted for a [GitHub Personal Access Token](https://github.com/settings/tokens).

For example, running `organization_gem_dependencies rails --direct --gems railties,rake` produces output
like the following:

```json
{
  "railties": {
    "4.0.0.beta": [
      "routing_concerns/Gemfile.lock"
    ],
    "4.0.0": [
      "prototype-rails/Gemfile.lock"
    ],
    "4.2.1": [
      "rails-perftest/Gemfile.lock"
    ],
    "4.2.10": [
      "rails-docs-server/test/fixtures/releases/v4.2.10/Gemfile.lock"
    ],
    "5.1.1": [
      "actioncable-examples/Gemfile.lock"
    ],
    "5.2.1": [
      "rails_fast_attributes/Gemfile.lock"
    ],
    "5.2.2": [
      "globalid/Gemfile.lock"
    ],
    "6.0.1": [
      "webpacker/Gemfile.lock"
    ],
    "6.0.2.1": [
      "rails-contributors/Gemfile.lock"
    ],
    "6.1.0.alpha": [
      "rails/Gemfile.lock"
    ]
  },
  "rake": {
    "0.9.2.2": [
      "commands/Gemfile.lock",
      "etagger/Gemfile.lock",
      "routing_concerns/Gemfile.lock"
    ],
    "10.1.0": [
      "prototype-rails/Gemfile.lock"
    ],
    "10.4.2": [
      "jquery-ujs/Gemfile.lock",
      "rails-perftest/Gemfile.lock"
    ],
    "10.5.0": [
      "rails_fast_attributes/Gemfile.lock",
      "record_tag_helper/Gemfile.lock"
    ],
    "12.0.0": [
      "actioncable-examples/Gemfile.lock",
      "rails-docs-server/test/fixtures/releases/v4.2.10/Gemfile.lock",
      "rails-dom-testing/Gemfile.lock"
    ],
    "12.3.2": [
      "globalid/Gemfile.lock"
    ],
    "13.0.0": [
      "webpacker/Gemfile.lock"
    ],
    "13.0.1": [
      "rails-contributors/Gemfile.lock",
      "rails/Gemfile.lock"
    ]
  }
}

```
