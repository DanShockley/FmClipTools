#! /bin/sh# make
#
# Make file for FmObjectTranslator.app
#
# Daniel Shockley, NYHTC. 
# 
# 2019-03-08 ( eshagdar ): check for app existence, then quit and delete
#     it before compiling a new one. Notify user that app is compiled.
# 2019-03-07 ( dshockley ): created
# 

APP_NAME="FmObjectTranslator.app"
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AS_PATH=$ROOT_DIR/Scripts/fmObjectTranslator.applescript


cd "$ROOT_DIR"

if [ -d "$APP_NAME" ]
then 
    # quit app if it's running
    osascript -e 'Tell application "'"$APP_NAME"'" to quit'

    # delete app if it exists
    if [ -d "$APP_NAME" ]; then rm -Rf $APP_NAME; fi
fi

# compile and notify user
osacompile -s -o "$APP_NAME" "$AS_PATH"
echo "compiled $APP_NAME"
