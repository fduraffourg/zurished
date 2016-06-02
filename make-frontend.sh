#!/bin/sh

TARGET=$PWD/target

if [ ! -d "$TARGET" ]
then
    mkdir $TARGET
fi

jsout=`mktemp --suffix=.js`

cd frontend
elm-make --yes Main.elm --output $jsout

replace_match_with_file() {
    line=`grep -n "$pattern" $src | cut -f 1 -d ':'`
    head -n $((line-1)) $src > $out
    echo $opening >> $out
    cat $file >> $out
    echo $closing >> $out
    tail -n +$((line+1)) $src >> $out
}

# Insert CSS style
src=dev.html
out=`mktemp`
pattern="href=\"style.css\""
file=style.css
opening="<style>"
closing="</style>"
replace_match_with_file

# Insert JS code
src=$out
out=$TARGET/index.html
pattern="src=\"dev.js\""
file=$jsout
opening="<script type=\"text/javascript\">"
closing="</script>"
replace_match_with_file
