echo "post commit, message: " $1
git commit -a -m "($1)"
git push -u origin master
