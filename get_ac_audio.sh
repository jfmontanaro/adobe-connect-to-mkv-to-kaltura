#!/bin/bash
set -e
if [ $# -lt 1 ];then
    echo "Usage $0 <recording ID>"
    exit 1
fi
ID="$1"
TMP=$ID/tmp
if [ -z "$OUTDIR" ];then
    OUTDIR=/tmp/ac_output
fi
mkdir -p $OUTDIR
cd $OUTDIR
rm -rf $ID
mkdir -p $TMP
COOKIE=`curl -I "$AC_ENDPOINT/api/xml?action=login&login=$AC_USERNAME&password=$AC_PASSWD"|grep "Set-Cookie:"|awk -F " " '{print $2}'`
if [ ! -r $ID.zip ];then
        curl -q -b "$COOKIE" "$AC_ENDPOINT/$ID/output/$ID.zip?download=zip" > $ID.zip
fi

unzip -o -d $TMP $ID.zip

VOIP=($(ls $TMP/cameraVoip*.flv | sort --version-sort -f))
if [ -z "$VOIP" ];then
        VOIP=($(ls $TMP/ftvoice*_*.flv | sort --version-sort -f))
fi
if [ -z "$VOIP" ];then
        echo "$ID.zip does contains neither cameraVoip*.flv nor ftvoice*.flv files. Exiting:("
        exit 2
fi

for i in "${!VOIP[@]}"; do
    FILENAME=$(printf "%0*d" 4 $i)
    ffmpeg -i "${VOIP[$i]}" -y $ID/$FILENAME.mp3
done
rm -f $ID.list
for f in $ID/*.mp3; do echo "file '$PWD/$f'" >>$ID.list; done

OUTPUT_FILE="$OUTDIR/$ID.mp3"
ffmpeg -f concat -safe 0 -i $ID.list -c copy -y $OUTPUT_FILE
if [ ! -r $OUTPUT_FILE ];then
	echo "Failed to generate $OUTPUT_FILE."
	exit 3
fi
echo "Final output saved to $OUTPUT_FILE"

