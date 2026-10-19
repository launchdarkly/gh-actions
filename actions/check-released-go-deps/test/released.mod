// Every enforced (github.com/launchdarkly/) module is at a released version. Third-party
// modules may use pseudo-versions. Comments and the module, retract, exclude, tool,
// toolchain, and godebug directives are not dependencies, so they are not checked.
module github.com/launchdarkly/example/v2

go 1.24

toolchain go1.24.4

godebug default=go1.21

require github.com/launchdarkly/go-server-sdk/v7 v7.19.0

require (
	github.com/gregjones/httpcache v0.0.0-20180305231024-9cad4c3443a7
	github.com/launchdarkly/go-sdk-common/v3 v3.6.0
	github.com/launchdarkly/go-semver v1.0.3 // indirect
	github.com/launchdarkly/legacy-module v2.1.0+incompatible // indirect
	github.com/patrickmn/go-cache v2.1.0+incompatible // indirect
	github.com/pmezard/go-difflib v1.0.1-0.20181226105442-5d4384ee4fb2 // indirect
)

// Was github.com/launchdarkly/go-sdk-events/v3 v3.6.4-0.20260924143011-673b754687b1.

tool github.com/launchdarkly/example/v2/cmd/generate

exclude github.com/launchdarkly/go-sdk-common/v3 v3.6.1-rc.1

retract [v2.0.0, v2.0.1] // Published by mistake.

replace github.com/gregjones/httpcache => ../httpcache

replace github.com/pmezard/go-difflib => github.com/launchdarkly/go-difflib v1.0.0
