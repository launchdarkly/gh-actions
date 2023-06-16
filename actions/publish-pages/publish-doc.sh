set -e

# Get the full docs path.
full_input_path="$(pwd)/$DOCS_PATH"

# Action should have cloned the gh-pages to a subdirectory.
cd gh-pages

# When running on CI we need to configure github before we commit.
if [ -n "${CI:-}" ]; then
  git config --local user.email "github-actions[bot]@users.noreply.github.com"
  git config --local user.name "github-actions[bot]"
fi

# Grep returns a non-zero exit code for no matches, so we want to ingore it.
set +e
existing_doc=$(git ls-files | grep -c "$OUT_PATH")
set -e

if [ "$existing_doc" != "0" ]; then
  echo "There are existing docs; removing them."
  git rm -r "$OUT_PATH"
  git commit -m "chore: Removed old docs for $OUT_PATH"
else
  echo "There are no existing docs; skipping removal."
fi

mkdir -p "$OUT_PATH"

# Copy the new docs.
cp -R "$full_input_path" "$OUT_PATH"/

git add "$OUT_PATH"

git commit -m "chore: Updating docs for $OUT_PATH"

# Update the local copy in case there have been any interim changes.

git config pull.rebase false # merge

head_sha=""

set +e

# Handle the possibility of concurrent doc updates by pulling in any new changes.
while true; do

  git pull origin "$PAGES_BRANCH" --no-edit # should accept the default message
  after_pull_sha=$(git rev-parse HEAD)

  # The first time this runs the head_sha will be empty and they will not match.
  # If the push fails, then we pull again, and if the SHA does not change, then
  # the push will not succeed.
  if [ "$head_sha" == "$after_pull_sha" ]; then
    echo "Failed to get changes. Could not publish docs."
    exit 1
  fi

  head_sha=$after_pull_sha

  if git push; then
    break
  fi

  echo "Push failed, trying again."
done

set -e
