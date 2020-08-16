curl http://nuc:2019/config/ 2>/dev/null | jq -r '.apps.http.servers[].routes[].match[].host[]'
