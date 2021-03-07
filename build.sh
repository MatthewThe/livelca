rake assets:clean
RAILS_ENV=production bundle exec rails assets:precompile
git_rev=$(git log -1 --pretty=%h)
docker build . -t matthewthe/livelca:${git_rev}
docker tag matthewthe/livelca:${git_rev} matthewthe/livelca:latest
