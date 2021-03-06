#!/bin/bash  -x

# Copyright 2015 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#export OSE_HOST=openshift.default.svc.cluster.local

function create_pgpass() {
cd /tmp
cat >> ".pgpass" <<-EOF
*:*:*:*:${PG_MASTER_PASSWORD}
EOF
chmod 0600 .pgpass
export PGPASSFILE=/tmp/.pgpass
}

create_pgpass

if [ ! -v SLEEP_TIME ]; then
	SLEEP_TIME=10
fi
echo "SLEEP_TIME is set to " $SLEEP_TIME

export PG_MASTER_SERVICE=$PG_MASTER_SERVICE
export GIT_USER_NAME=$GIT_USER_NAME
export GIT_USER_EMAIL=$GIT_USER_EMAIL
export PG_MASTER_PORT=$PG_MASTER_PORT
export PG_MASTER_USER=$PG_MASTER_USER
export PG_DATABASE=$PG_DATABASE

if [ -d /usr/pgsql-9.5 ]; then
        export PGROOT=/usr/pgsql-9.5
elif [ -d /usr/pgsql-9.4 ]; then
        export PGROOT=/usr/pgsql-9.4
else
        export PGROOT=/usr/pgsql-9.3
fi

echo "setting PGROOT to " $PGROOT

export PATH=$PATH:/opt/cpm/bin:$PGROOT/bin


git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_EMAIL
git config --global push.default simple

pg_dump --schema-only --username=$PG_MASTER_USER --dbname=$PG_DATABASE \
	--host=$PG_MASTER_SERVICE > /tmp/schema.sql

cd /gitrepo
GIT_PROJECT=`ls | cut -f1 -d' '`
cd $GIT_PROJECT
cp /tmp/schema.sql .
git add schema.sql
git commit -am 'update schema version'
git push

#while true; do 
#	sleep $SLEEP_TIME
#done
