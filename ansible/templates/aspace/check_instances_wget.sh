#! /usr/bin/env bash

SCRIPT=$(readlink -f "$0")
DIR_SCRIPT=$(dirname "$SCRIPT")
. $DIR_SCRIPT/venv_twill/bin/activate

sites=(http://public.ucm.aspace.cdlib.org
 http://public.ucmppdc.aspace.cdlib.org
 http://public.ucr.aspace.cdlib.org
 http://public.ucsc.aspace.cdlib.org
 http://public.ucrcmp.aspace.cdlib.org
 http://public.ucbeda.aspace.cdlib.org
 http://public.uclaclark.aspace.cdlib.org
 http://public.ucsf.aspace.cdlib.org )

for url in "${sites[@]}"
do
	echo "CHECK $url"
        wget -q --spider $url
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
        wget -q --spider $url/search?type=repository
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
        wget -q --spider $url/search?type=resource
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
        wget -q --spider $url/search?type=digital_object
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
        wget -q --spider $url/search?type=accession
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
        wget -q --spider $url/search?type=subject
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
        wget -q --spider $url/search?type=agent
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
        wget -q --spider $url/search?type=classification
        if [ $? != 0 ]; then
            echo "FAILED FOR $url"
            break
        fi
done
