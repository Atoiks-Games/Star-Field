LOVE2D_VER="11.1.0"

GENERIC_NAME="star-field"

OUTPUT_DIR="./build/"
OUTPUT_ZIP=$OUTPUT_DIR"star-field.love"
OUTPUT_WIN=$OUTPUT_DIR"star-field-win"
OUTPUT_MAC=$OUTPUT_DIR"star-field.app"

RUNTIME_WIN=$OUTPUT_DIR"love-"$LOVE2D_VER"-win"

BUILD_ZIP=false
BUILD_WIN=false

# $1: Windows runtime directory
# $2: Final result directory that contains everything needed for the packaged game
function buildWin {
    mkdir -p $2
    cat $1/love.exe $OUTPUT_ZIP > "$2/Star Field.exe"

    # Copy necessary files
    cp $1/SDL2.dll $2
    cp $1/OpenAL32.dll $2
    cp $1/license.txt $2
    cp $1/love.dll $2
    cp $1/lua51.dll $2
    cp $1/mpg123.dll $2
    cp $1/msvcp120.dll $2
    cp $1/msvcr120.dll $2
}

case "$1" in
"help")
    echo ""
    echo "$0 [OPTIONS]"
    echo "  help:  Displays this message"
    echo "  clean: Deletes the builds"
    echo "  love:  Builds the love file"
    echo "         alias:zip"
    echo "  win:   Packages for windows, will build love file first,"
    echo "         requires windows runtime in build folder"
    echo "         alias:windows"
    echo ""
    exit 0
    ;;
"clean")
    rm -rf $OUTPUT_ZIP $OUTPUT_WIN*
    ;;
"love" | "zip")
    BUILD_ZIP=true
    ;;
"win" | "windows")
    if [ ! -f $OUTPUT_ZIP ]; then
        BUILD_ZIP=true
    fi
    BUILD_WIN=true
    ;;
*)
    echo "Unknown argument $1, do '$0 help' for more"
    exit 1
    ;;
esac

mkdir -p $OUTPUT_DIR

if $BUILD_ZIP
then
    cd ./src
    zip -9 -r ../$OUTPUT_ZIP .
    cd ..
fi

if $BUILD_WIN
then
    # Try 32-bit first
    if [ -d $RUNTIME_WIN"32" ]
    then
        buildWin $RUNTIME_WIN"32/" $OUTPUT_WIN"32/"
    else
        echo "Cannot find "$RUNTIME_WIN"32"
        echo "Trying 64 bit runtime"
    fi

    # Try 64-bit
    if [ -d $RUNTIME_WIN"64" ]
    then
        buildWin $RUNTIME_WIN"64/" $OUTPUT_WIN"64/"
    else
        echo "Cannot find "$RUNTIME_WIN"64"
    fi
fi