#! /bin/env python

import os
import subprocess
from os.path import isdir, join, abspath

tenant_root='/aspace/archivesspace/tenants'
directories = [d for d  in os.listdir(tenant_root) if isdir(join(tenant_root, d))]
for d in directories:
   if '_template' not in d:
        os.chdir(abspath(join(tenant_root, d, 'archivesspace')))
	p = subprocess.Popen('scripts/setup-database.sh')
        p.wait()
print p
