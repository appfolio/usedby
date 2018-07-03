# organization_gem_dependencies

This gem installs a command line utility `organization_gem_dependencies`, that
outputs a json file with a reverse dependency tree.


## Installation

```sh
gem install organization_gem_dependencies
```

## Usage

```sh
organization_gem_dependencies [--direct] GITHUB_ORGANIZATION
```

For example, running `organization_gem_dependencies -d rails` produces output
like the following:

```json
{
  ...,
  "rails": {
    "4.0.0.beta": [
      "routing_concerns/Gemfile.lock"
    ],
    "4.2.10": [
      "rails-docs-server/test/fixtures/releases/v4.2.10/Gemfile.lock"
    ],
    "5.1.1": [
      "actioncable-examples/Gemfile.lock"
    ],
    "5.2.0": [
      "rails-contributors/Gemfile.lock",
      "webpacker/Gemfile.lock"
    ],
    "6.0.0.alpha": [
      "rails/Gemfile.lock"
    ]
  },
  "rails-controller-testing": {
    "1.0.2": [
      "rails-contributors/Gemfile.lock"
    ]
  },
  "rails-dom-testing": {
    "2.0.2": [
      "rails-dom-testing/Gemfile.lock"
    ]
  },
  "rails-perftest": {
    "0.0.7": [
      "rails-perftest/Gemfile.lock"
    ]
  },
  "railties": {
    "4.2.1": [
      "rails-perftest/Gemfile.lock"
    ],
    "5.1.4": [
      "globalid/Gemfile.lock"
    ]
  },
  "rake": {
    "0.9.2.2": [
      "commands/Gemfile.lock",
      "etagger/Gemfile.lock",
      "routing_concerns/Gemfile.lock"
    ],
    "10.0.3": [
      "strong_parameters/Gemfile.lock"
    ],
    "10.0.4": [
      "cache_digests/Gemfile.lock"
    ],
    "10.3.2": [
      "activemodel-globalid/Gemfile.lock"
    ],
    "10.4.2": [
      "jquery-ujs/Gemfile.lock",
      "record_tag_helper/Gemfile.lock"
    ],
    "12.0.0": [
      "rails-docs-server/test/fixtures/releases/v4.2.10/Gemfile.lock",
      "rails-dom-testing/Gemfile.lock"
    ],
    "12.1.0": [
      "globalid/Gemfile.lock"
    ],
    "12.3.1": [
      "rails/Gemfile.lock",
      "webpacker/Gemfile.lock"
    ]
  },
  ...
}
```