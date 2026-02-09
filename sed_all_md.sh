for f in $(find -type f -name "*.md"); do 
  echo $f 
  sed -i -E 's/\bgit([-_ ])issue\b/git\1pad/' $f
done

