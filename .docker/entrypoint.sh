#!/bin/bash

# See: https://docs.docker.com/samples/rails/
mkdir -p tmp/pids
rm -f tmp/pids/server.pid

if [ ! -e Gemfile.local ]; then
  echo "gem 'puma'" > Gemfile.local
  echo "gem 'letter_opener_web'" >> Gemfile.local
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
default: &default
  adapter: postgresql
  host: <%= ENV['POSTGRES_HOST'] %>
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>
  encoding: utf8

production:
  <<: *default
  database: <%= ENV['POSTGRES_DB'] %>

development:
  <<: *default
  database: redmine_development

test:
  <<: *default
  database: redmine_test
  template: template0
EOS
fi

if [ ! -e config/configuration.yml ]; then
  cat << EOS > config/configuration.yml
default:
  email_delivery:
    delivery_method: :letter_opener_web

  minimagick_font_path: /usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
EOS
fi

bundle install

if [ ! -e config/initializers/secret_token.rb ]; then
  bin/rails generate_secret_token
fi

bin/rails db:migrate redmine:plugins:migrate RAILS_ENV=production
# bin/rails db:fixtures:load RAILS_ENV=production

# See: https://www.redmine.org/projects/redmine/wiki/repositories_access_control_with_apache_mod_dav_svn_and_mod_perl
gem install activeresource
chown -R www-data:www-data /var/git
# ruby extra/svn/reposman.rb -s /var/git -r localhost:3000 -u /var/git/ --scm git --owner www-data --key "Repository management WS API key"

# See: doc/RUNNING_TESTS
# bin/rails db:create db:migrate redmine:plugins:migrate RAILS_ENV=test
# bin/rails test:scm:setup:all
# See: https://www.redmine.org/issues/33784
# rm -fr tmp/test/mercurial_repository
# bin/rails log:clear
# bin/rails test RAILS_ENV=test
# bin/rails test:system RAILS_ENV=test
# bin/rails test:scm:update

exec "$@"
