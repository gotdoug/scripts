#!/bin/bash

var1=TesT
var2=tEst

echo ${var1,,} ${var2,,} ## will output all lower case
echo ${var1^^} ${var2^^} ## will output all upper case

## ${parameter,,} converts all characters in a string to lower case. If you wanted to convert to upper case,
## use ${parameter^^}. If you want to convert just some of the characters, use ${parameter,,pattern} where
## only those characters matching pattern are changed. Still more details on this are documented by man bash:
## 
## ${parameter^pattern}
## ${parameter^^pattern} 
## ${parameter,pattern} 
## ${parameter,,pattern}
## 
## Case modification. This expansion modifies the case of alphabetic characters in parameter. The pattern
## is expanded to produce a pattern just as in pathname expansion. The ^ operator converts lowercase letters
## matching pattern to uppercase; the , operator converts matching uppercase letters to lowercase. The ^^ 
## and ,, expansions convert each matched character in the expanded value; the ^ and , expansions match and
## convert only the first character in the expanded value. If pattern is omitted, it is treated like a ?, 
## which matches every character. If parameter is @ or *, the case modification operation is applied to each
## positional parameter in turn, and the expansion is the resultant list. If parameter is an array variable
## subscripted with @ or *, the case modification operation is applied to each member of the array in turn,
## and the expansion is the resultant list.
