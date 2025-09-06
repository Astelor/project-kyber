#!/bin/bash
# this shell scirpt removes the '//' commented lines and spaces
# and DIRECTLY writes back to the original file
# this is used for the modelsim 'mem save -noaddress -wordsperline 1' output

sed -i 's/ //g' $@
sed -i '/\/\//d' $@

