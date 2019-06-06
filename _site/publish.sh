git checkout src
docker-compose run --rm web bundle exec jekyll build
rm -rf /tmp/_site
cp -rf _site /tmp/
rm -rf *
git checkout master
cp -rf /tmp/_site/* ./
git add .
git commit -am "Updated at $(date)"
git push -f origin master
git checkout src
