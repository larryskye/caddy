#!/usr/bin/env bash
set -o errexit  # Exit on most errors (see the manual)
set -o errtrace # Make sure any error trap is inherited
set -o nounset  # Disallow expansion of unset variables
set -o pipefail # Use last non-zero exit code in a pipeline

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASE=$DIR/base-caddyfile
TARGET=$DIR/config/Caddyfile

# Get Caddyfile's from app dirs
FILES=$(find $DIR/../*/ -maxdepth 1 -name Caddyfile)

cat $BASE > $TARGET

for f in $FILES; do 
  echo "" >> $TARGET;
  echo "# FROM ${f}" >> $TARGET;
  (cat "${f}"; echo) >> $TARGET; 
done

# Use docker labels
containers=$(docker ps --filter "label=dev.server.expose.port" | awk '{if(NR>1) print $NF}')
for container in $containers
do
  subdomain=$(docker inspect $container --format '{{index .Config.Labels "dev.server.expose.subdomain" }}')
  port=$(docker inspect $container --format '{{index .Config.Labels "dev.server.expose.port" }}')
  is_public=$(docker inspect $container --format '{{index .Config.Labels "dev.server.expose.public" }}')
  if [ "$is_public" = true ] ; then
	cat << EOF >> $TARGET
# FROM DOCKER LABELS FOR $container
$subdomain.{\$ZONE} {
  import defaults
  reverse_proxy $container:$port {
    import proxy_options
  }
}
EOF
  else
	cat << EOF >> $TARGET
# FROM DOCKER LABELS FOR $container
$subdomain.{\$ZONE} {
  import internal_only
  import defaults
  reverse_proxy $container:$port {
    import proxy_options
  }
}
EOF
  fi

done

caddy_container_id=$(docker ps | grep caddy| awk '{print $1;}')
docker exec $caddy_container_id caddy reload --config /etc/caddy/Caddyfile --adapter caddyfile
docker-compose logs --tail=20 | grep "load complete"
