RAILS_ENV=production bundle exec rails assets:precompile
docker build . -t matthewthe/livelca:latest
