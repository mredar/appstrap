#check if ingest is idle
# takes output from rqinfo and parses to see if not idle
import sys, os
from rq import Queue, Worker
from rq.scripts import (setup_default_arguments, setup_redis)

settings = { 'REDIS_PASSWORD':
                os.environ.get('REDIS_PASSWORD', {{ REDIS_PASSWORD }})
           }

class Args:
    url = None
    host = None
    port = 6379
    db = None
    socket = None
    password = settings['REDIS_PASSWORD']

setup_default_arguments(Args(), settings)
setup_redis(Args())

qs = Queue.all()

for Q in qs:
    if Q.count > 0:
        sys.exit(11)

workers = Worker.all()
for w in workers:
    if w.get_state() != 'idle':
        sys.exit(12)

sys.exit(0)
