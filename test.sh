
containers=$(docker ps --filter "label=dev.server.expose.port" | awk '{if(NR>1) print $NF}')
for container in $containers
do
  subdomain=$(docker inspect $container --format '{{index .Config.Labels "dev.server.expose.subdomain" }}')
  port=$(docker inspect $container --format '{{index .Config.Labels "dev.server.expose.port" }}')
  echo "Container: $container"
  echo "$subdomain -> $port"
done


