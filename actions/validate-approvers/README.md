# Validate Approvers Action

This action validates that at least one approver of a pull request belongs to the required team. For use in LaunchDarkly repositories to ensure all PRs are approved by a non-contingent LaunchDarkly employee.

## Usage

A GitHub Actions workflow that uses this action might look like this:
```
name: Require valid approvers
on:
  pull_request_review:
    types: [submitted]

jobs:
  validate-approvers:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - uses: launchdarkly/gh-actions/actions/validate-approvers
        if: github.event.review.state == 'approved'
        with:
          github-token: ${{ secrets.GH_PAT }} # Pass in a GitHub token with API access
          repository-owner: "${{ github.repository_owner }}"
          repository: "${{ github.repository }}"
          pull-request-number: ${{ github.event.pull_request.number }}
          required-team: "role-product-engineers" # ROLE - Product Engineers only consists of full-time LaunchDarkly employees

```
