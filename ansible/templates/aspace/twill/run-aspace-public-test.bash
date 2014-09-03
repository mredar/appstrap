#! /usr/bin/env bash

set -o errexit

twill-sh test-public.tw  --url http://ucm.aspace.cdlib.org
twill-sh test-public.tw  --url http://ucr.aspace.cdlib.org
twill-sh test-public.tw  --url http://ucsf.aspace.cdlib.org
twill-sh test-public.tw  --url http://ucsc.aspace.cdlib.org
twill-sh test-public.tw  --url http://ucbeda.aspace.cdlib.org
twill-sh test-public.tw  --url http://ucrcmp.aspace.cdlib.org
twill-sh test-public.tw  --url http://ucmppdc.aspace.cdlib.org
twill-sh test-public.tw  --url http://uclaclark.aspace.cdlib.org
#SHUTDOWN Aug 2014 twill-sh test-public.tw  --url http://ucdavis.aspace.cdlib.org
