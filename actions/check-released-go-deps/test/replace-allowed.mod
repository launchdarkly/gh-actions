// The require line is exempt when allowed lists it. The replace of the same module@version is not.
module github.com/launchdarkly/example/v2

go 1.24

require github.com/launchdarkly/go-server-sdk/v7 v7.19.0

require github.com/launchdarkly/api-client-go/v13 v13.0.1-0.20230420175109-f5469391a13e

replace (
	github.com/launchdarkly/api-client-go/v13 v13.0.1-0.20230420175109-f5469391a13e => ../api-client-go
)
