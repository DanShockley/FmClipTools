#! /bin/sh# make
#
# Make file for FmObjectTranslator.app
#
# NYHTC. 2019-03-07 ( dshockley )
# 


root_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
scriptPath=$root_dir/Scripts/fmObjectTranslator.applescript


cd "$root_dir";osacompile -s -o "FmObjectTranslator.app" "$scriptPath"
