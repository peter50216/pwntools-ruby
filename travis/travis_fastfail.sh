#!/bin/sh
# This file is modified from code in Julia.
# License is MIT: http://julialang.org/license

curlhdr="Accept: application/vnd.travis-ci.2+json"
endpoint="https://api.travis-ci.org/repos/$TRAVIS_REPO_SLUG"

# Fail fast for superseded builds to PR's
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  newestbuildforthisPR=$(curl -H "$curlhdr" "$endpoint/builds?event_type=pull_request" | \
      jq ".builds | map(select(.pull_request_number == $TRAVIS_PULL_REQUEST))[0].number")
  if [ "$newestbuildforthisPR" != null ] && [ "$newestbuildforthisPR" != "\"$TRAVIS_BUILD_NUMBER\"" ]; then
    echo "There are newer queued builds for this pull request, failing early."
    exit 1
  fi
fi
