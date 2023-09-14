# Publish Pages

This action can be used to publish documentation to github pages.

# Requirements

The repository should have github pages enabled.

# Example

Publishing the 'docs' directory to the root of the github pages branch.
```
- uses: launchdarkly/gh-actions/actions/publish-pages
  name: 'Publish to Github pages'
  with:
    docs_path: docs
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

Publishing from a subdirectory to a sub-directory. This may be done for different
packages in a monorepo.
```
- uses: launchdarkly/gh-actions/actions/publish-pages
  name: 'Publish to Github pages'
  with:
    docs_path: packages/potato/docs
    output_path: packages/potato
    github_token: ${{ secrets.GITHUB_TOKEN }}
```