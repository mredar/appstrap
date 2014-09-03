#! /usr/bin/env bash

set -o errexit

twill-fork test-public.tw  --url http://ucm.aspace.cdlib.org --number=30 --processes=3 &
twill-fork test-public.tw  --url http://ucr.aspace.cdlib.org --number=30 --processes=3 &
twill-fork test-public.tw  --url http://ucsf.aspace.cdlib.org --number=30 --processes=3 
twill-fork test-public.tw  --url http://ucsc.aspace.cdlib.org --number=30 --processes=3
twill-fork test-public.tw  --url http://ucbeda.aspace.cdlib.org --number=30 --processes=3
twill-fork test-public.tw  --url http://ucrcmp.aspace.cdlib.org --number=30 --processes=3
twill-fork test-public.tw  --url http://uclaclark.aspace.cdlib.org --number=30 --processes=3
twill-fork test-public.tw  --url http://ucmppdc.aspace.cdlib.org --number=30 --processes=3
#SHUTDOWN Aug 2014 twill-fork test-public.tw  --url http://ucdavis.aspace.cdlib.org --number=30 --processes=3
