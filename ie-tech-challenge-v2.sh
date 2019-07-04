#!/bin/bash
#Make request
function get_latest_server_info() {
  curl --request POST \
    --header 'Content-type: application/json' \
    --data '{"jsonrpc":"2.0","method":"server_info","params":[{}]}' \
    s1.ripple.com:51234
}
#extract out
function extract_data_to_csv() {
  rippled_server_info=$(get_latest_server_info)
  server_info_time=$(echo $rippled_server_info | sed -E 's/.*time\":\"(.*)\",\"uptime.*/\1/')
  server_info_seq=$(echo $rippled_server_info | sed -E 's/.*seq\":(.*)\},\"validation_quorum.*/\1/')
  echo "$server_info_time $server_info_seq" >> ie-tech-challenge.csv
}

# do polling
while $(extract_data_to_csv)
do
	# re-generate graph
  	$(gnuplot ./ie-tech-challenge.p)
  	sleep 4;
done