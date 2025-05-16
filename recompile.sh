#! /bin/sh# make
#
# Does a git pull and then runs the make file for FmObjectTranslator.app
#
# 2019-03-07 ( eshagdar ): Created.


ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $ROOT_DIR
git pull -q

. make.sh
