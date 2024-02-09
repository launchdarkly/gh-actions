# Default Branch

This action discovers the default branch of the repository (from Github's point of view). This is useful for
running certain workflows only on the default branch, even if the workflow is checked into multiple branches.

It might also be useful in package publishing - the motivating scenario for this action is only pushing Docker `latest`
tags from the default branch. 


# Example

```yml
jobs:
  do-something:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v3
      - uses: launchdarkly/gh-actions/actions/default-branch@default-branch-v1.0.0
        id: default-branch
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      - name: Do something if we're on default
        if: steps.default-branch.outputs.condition == 'true'
        run: echo "We're on the default branch!"
      - name: So what is the default branch, anyways? 
        run: echo "The default branch is ${{ steps.default-branch.outputs.value }}"
```
