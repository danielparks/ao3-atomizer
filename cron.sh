#!/bin/bash

set -e

# Move to script directory
cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1

# URL example: https://archiveofourown.org/works/11478249
for url in "$@" ; do
  mkdir -p "static/$(dirname "${url#http*://}")"
  mkdir -p "work/$(dirname "${url#http*://}")"

  ### FIXME? Could do with some locking.
  bundle exec process.rb "$url" > "work/${url#http*://}.atom"
  mv "work/${url#http*://}.atom" "static/${url#http*://}.atom"
done
