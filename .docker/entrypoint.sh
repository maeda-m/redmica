#!/bin/bash

# See: https://docs.docker.com/samples/rails/
mkdir -p tmp/pids
rm -f tmp/pids/server.pid

if [ ! -e Gemfile.local ]; then
  echo "gem 'puma'" > Gemfile.local
fi

if [ ! -e config/puma.rb ]; then
  cat << EOS > config/puma.rb
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS') { max_threads_count }
threads min_threads_count, max_threads_count

port ENV.fetch('PORT', 3000)
environment ENV.fetch('RAILS_ENV') { 'development' }
pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }
plugin :tmp_restart
EOS
fi

if [ ! -e config/database.yml ]; then
  cat << EOS > config/database.yml
production:
  adapter: postgresql
  database: <%= ENV['POSTGRES_DB'] %>
  host: <%= ENV['POSTGRES_HOST'] %>
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>
  encoding: utf8

test:
  adapter: postgresql
  database: redmine_test
  host: <%= ENV['POSTGRES_HOST'] %>
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>
  encoding: utf8
  template: template0
EOS
fi

bundle install

if [ ! -e config/initializers/secret_token.rb ]; then
  bin/rails generate_secret_token
fi

bin/rails db:migrate redmine:plugins:migrate RAILS_ENV=production

# See: doc/RUNNING_TESTS
# bin/rails db:create db:migrate redmine:plugins:migrate RAILS_ENV=test
# bin/rails test:scm:setup:all
# See: https://www.redmine.org/issues/33784
# rm -fr tmp/test/mercurial_repository
# PARALLEL_WORKERS=8 RAILS_ENV=test bundle exec rails test
# bin/rails test:scm:update

exec "$@"
