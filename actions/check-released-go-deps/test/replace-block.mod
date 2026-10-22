module github.com/launchdarkly/example/v2

go 1.24

require github.com/launchdarkly/go-server-sdk/v7 v7.19.0

replace (
	github.com/gregjones/httpcache => ../httpcache
	github.com/launchdarkly/go-server-sdk/v7 v7.19.0 => github.com/launchdarkly/go-server-sdk/v7 v7.19.0
)
