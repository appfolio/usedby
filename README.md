# usedby

Figure out where your gems are actually being used!
Similar to GitHub's "Used By" feature, but for private repos.

This gem installs a command line utility `usedby`, that
outputs a json file with a reverse dependency tree.

This acts more or less like GitHub's "Used By" feature.
It currently uses GitHub's code search API which has a few limitations:
https://help.github.com/en/github/searching-for-information-on-github/searching-code

## Installation

```sh
gem install usedby
```

## Usage

```sh
usedby GITHUB_ORGANIZATION [--direct] [--gems GEM1,GEM2,GEM3] [--order gems|projects]
```

You will be securely prompted for a [GitHub Personal Access Token](https://github.com/settings/tokens).

For example, running `usedby rails --gems railties,rake --order gems` produces output
like the following:

```json
{
  "railties": {
    "4.0.0.beta": [
      "routing_concerns/Gemfile.lock"
    ],
    "4.0.0": [
      "prototype-rails/Gemfile.lock"
    ]
  },
  "rake": {
    "0.9.2.2": [
      "routing_concerns/Gemfile.lock"
    ],
    "10.1.0": [
      "prototype-rails/Gemfile.lock"
    ]
  }
}
```

On the other hand, running `usedby rails --gems railties,rake --order projects` produces output
like the following:

```json
{
  "prototype-rails": {
    "railties": "4.0.0.beta",
    "rake": "10.1.0"
  },
  "routing_concerns": {
    "railties": "4.0.0.beta",
    "rake": "0.9.2.2"
  }
}
```
