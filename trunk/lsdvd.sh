#!/bin/sh

# lsdvd.sh
# SmallShrink
#
# Created by Richard Hughes on 06/09/2010.
# Copyright 2010 Small Software. All rights reserved.

rpath=`dirname "$0"`
echo `$rpath/lsdvd $*`\; 'print lsdvd' | python | sed s/\'/\"/g

