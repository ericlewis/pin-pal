#!/bin/zsh
# ci_post_xcodebuild.sh

# Tag name to use for the last successful build
LAST_SUCCESSFUL_BUILD_TAG="last-successful-build"

# Check if the signed app path exists
if [[ -d "$CI_APP_STORE_SIGNED_APP_PATH" ]]; then
  TESTFLIGHT_DIR_PATH=../TestFlight
  mkdir -p $TESTFLIGHT_DIR_PATH

  # Fetch the latest commits and tags
  git fetch --tags
  
  # Get the last successful build commit hash from the tag
  if git rev-parse $LAST_SUCCESSFUL_BUILD_TAG >/dev/null 2>&1; then
    LAST_COMMIT=$(git rev-parse $LAST_SUCCESSFUL_BUILD_TAG)
  else
    # If no tag is found, fallback to fetching the last commit
    LAST_COMMIT=$(git rev-parse HEAD^)
  fi

  # Get the current commit hash
  CURRENT_COMMIT=$(git rev-parse HEAD)

  # Get the list of commits between the last successful build and the current commit
  git log $LAST_COMMIT..$CURRENT_COMMIT --pretty=format:"%h - %s" >! $TESTFLIGHT_DIR_PATH/WhatToTest.en-US.txt

  # Tag the current commit as the new last successful build
  git tag -f $LAST_SUCCESSFUL_BUILD_TAG $CURRENT_COMMIT
  git push origin $LAST_SUCCESSFUL_BUILD_TAG
fi
