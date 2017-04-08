#!/bin/bash -e

# This script is inspired from similar scripts in the Kitura BluePic project

# Find our current directory
# current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z ${COUCHDB_PASSWORD} ]; then
  echo "Falling back..."
  echo "COUCHDB_PASSWORD environment variable is not set"
  exit
fi

export INSTALL_DIR="$HOME/couchdb"

if [ ! -e $INSTALL_DIR ]
then

   curl -O --retry 999 --retry-max-time 0 -C - http://apache.skazkaforyou.com/couchdb/releases/1.2.0/apache-couchdb-1.2.0.tar.gz
   tar -zxvf apache-couchdb-1.2.0.tar.gz
   cd apache-couchdb-1.2.0
   ./configure --prefix=$INSTALL_DIR --with-erlang=/usr/lib64/erlang/erts-5.8.5/include
   make
   make install

fi

# install our .ini
cat << 'EOF' > /usr/local/etc/couchdb/local.ini
[couchdb]
delayed_commits = false

[httpd]
port = 80
bind_address = 0.0.0.0
socket_options = [{recbuf, 262144}, {sndbuf, 262144}, {nodelay, true}]
WWW-Authenticate = Basic realm="administrator"
;WWW-Authenticate = bummer

[couch_httpd_auth]
require_valid_user = true

[log]
level = error

[admins]
EOF

# generate & set the initial password
echo "admin = ${ADMIN_PASSWORD}" >> /usr/local/etc/couchdb/local.ini

# add couchdb user
adduser --system --home /usr/local/var/lib/couchdb -M --shell /bin/bash --comment "CouchDB" couchdb

# change file ownership
chown -R couchdb:couchdb /usr/local/etc/couchdb /usr/local/var/lib/couchdb /usr/local/var/log/couchdb /usr/local/var/run/couchdb

# run couchdb on startup
ln -s /usr/local/etc/rc.d/couchdb /etc/init.d/couchdb
chkconfig --add couchdb
chkconfig --level 345 couchdb on

# done!
echo
echo
echo "Installation complete!"
echo "Couchdb admin password was set to: ${ADMIN_PASSWORD}"
echo
echo "Couchdb is ready to start. Run:"
echo "    sudo service couchdb start"


# # install couchdb dependancies
# sudo yum --enablerepo=epel install libicu-devel openssl-devel curl-devel make gcc erlang js-devel libtool which


# # Parse input parameters
# database=kitura_test_db
# url=http://127.0.0.1:5984

# for i in "$@"
# do
# case $i in
#     --username=*)
#     username="${i#*=}"
#     shift
#     ;;
#     --password=*)
#     password="${i#*=}"
#     shift
#     ;;
#     --url=*)
#     url="${i#*=}"
#     shift
#     ;;
#     *)
#     ;;
# esac
# done


# delete and create database to ensure it's empty
# curl -X DELETE $url/$database -u $username:$password
# curl -X PUT $url/$database -u $username:$password

# Upload design document
# curl -X PUT "$url/$database/_design/main_design" -u $username:$password \
#     -d @$current_dir/main_design.json

# Create data
# curl -H "Content-Type: application/json" -d @$current_dir/books.json \
#     -X POST $url/$database/_bulk_docs -u $username:$password

# echo
# echo "Finished populating couchdb database '$database' on '$url'"
