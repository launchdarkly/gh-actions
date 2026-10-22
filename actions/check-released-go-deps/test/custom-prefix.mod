// example.com/acme/ modules are released. The github.com/launchdarkly/ pseudo-version
// passes only when module_prefixes does not include github.com/launchdarkly/.
module example.com/acme/app

go 1.24

require (
	example.com/acme/lib v1.2.0
	github.com/gregjones/httpcache v0.0.0-20180305231024-9cad4c3443a7
	github.com/launchdarkly/go-server-sdk/v7 v7.19.2-0.20261019182248-5b041ff834f5
)
