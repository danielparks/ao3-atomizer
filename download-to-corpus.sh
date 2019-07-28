#!/bin/bash

set -e

# Move to script directory
cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1

# URL example: https://archiveofourown.org/works/11478249
for url in "$@" ; do
  work_path="corpus/${url#http*://}"

  mkdir -p "$work_path"
  curl -sSo "$work_path/navigate" "$url/navigate"
  curl -sSo "$work_path/?view_adult=true&view_full_work=true" \
    "$url/?view_adult=true&view_full_work=true"
done
