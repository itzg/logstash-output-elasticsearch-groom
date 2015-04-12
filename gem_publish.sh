#!/bin/sh

mkdir -p ~/.gem
echo ":rubygems_api_key: ${RUBYGEMS_API_KEY}" > ~/.gem/credentials
chmod 600 ~/.gem/credentials
bundle exec rake publish_gem