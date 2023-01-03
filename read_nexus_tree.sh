#! /bin/bash

nexus_file=$1

grep -A1 'Begin trees;' $nexus_file | sed 's/^[^(]\+(/(/' | nw_display -
