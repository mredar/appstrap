sudo docker run -d -p 5984:5984 -v /var/lib/couchdb --name=couchdb couchdb /run.sh
sudo docker run -d -p 8889:8889 --env-file akara-env.list --link couchdb:couchdb --name=akara akara-dpla /run.sh
