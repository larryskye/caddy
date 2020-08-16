#!/usr/bin/env bash
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASE=$DIR/base-caddyfile
TARGET=$DIR/config/Caddyfile

FILES=$(find $DIR/../*/ -maxdepth 1 -name Caddyfile)

cat $BASE > $TARGET

for f in $FILES; do 
  echo "" >> $TARGET;
  echo "# FROM ${f}" >> $TARGET;
  (cat "${f}"; echo) >> $TARGET; 
done

caddy_container_id=$(docker ps | grep caddy| awk '{print $1;}')
docker exec $caddy_container_id caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
docker-compose logs --tail=20 | grep "load complete"
