#!/usr/bin/env zsh

a=$1
b=${1//.actual}

nonulls='walk( if type == "object" then with_entries(select(.value != null)) else . end)'
nospans='walk( if type == "object" then with_entries(select(.key != "span")) else . end)'
noannot='walk( if type == "object" then with_entries(select(.key != "annotations")) else . end)'

npx jsondiffpatch <(jq -M "$nonulls | $nospans | $noannot" $b) $a
