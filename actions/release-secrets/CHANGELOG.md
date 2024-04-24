# Changelog

## [1.2.0](https://github.com/launchdarkly/gh-actions/compare/release-secrets-v1.1.0...release-secrets-v1.2.0) (2024-04-24)


### Features

* Add release-secrets action. ([#3](https://github.com/launchdarkly/gh-actions/issues/3)) ([1de7188](https://github.com/launchdarkly/gh-actions/commit/1de718801498a66c93410d02ff68d65b122f5485))
* Add the ability to get s3 resources with release-secrets. ([#16](https://github.com/launchdarkly/gh-actions/issues/16)) ([b8641e1](https://github.com/launchdarkly/gh-actions/commit/b8641e155b9bfc533454af64e1a83838f3f972c1))


### Bug Fixes

* Do not fetch ssm parameters if none are defined. ([#9](https://github.com/launchdarkly/gh-actions/issues/9)) ([645a0e9](https://github.com/launchdarkly/gh-actions/commit/645a0e9c064b985ea9052db6492e4c91dfd34e42))
* **release-secrets:** Pin aws/ssm-getparameters-action to a SHA ([#10](https://github.com/launchdarkly/gh-actions/issues/10)) ([e1d15b6](https://github.com/launchdarkly/gh-actions/commit/e1d15b633764b4eeb8d3122271ad18cdaf738913))
