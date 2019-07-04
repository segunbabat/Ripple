# IE Challenge

## Task
**Preface**: Transactions on the XRP Ledger are communicated and recorded by a network of computers running a software daemon called "rippled." Every few seconds, the network reaches consensus on a new set of transactions which are applied to the old state of the ledger to create a new “validated ledger” that gets broadcast across the network. You can use rippled’s server_info command to gather information about the set of validated ledgers that this rippled has received.

**Summary**: Write a script/program that periodically calls rippled’s server_info command and records the sequence number of the latest *validated ledger* along with the current time. Record this data in a file. Then, use this data to construct a plot (time on the x-axis, sequence number on the y-axis) that visualizes how frequently the ledger sequence is incremented over time (i.e. how often new ledgers are validated). Choose a time span and polling interval that can effectively capture and depict this information.

```sh
# ie-tech-challenge.sh
#!/bin/bash

# send server info request
function get_latest_server_info() {
  curl --request POST \
    --header 'Content-type: application/json' \
    --data '{"jsonrpc":"2.0","method":"server_info","params":[{}]}' \
    s1.ripple.com:51234
}

# extract data from request to csv file
function extract_data_to_csv() {
  rippled_server_info=$(get_latest_server_info)
  server_info_time=$(echo $rippled_server_info | sed -E 's/.*time\":\"(.*)\",\"uptime.*/\1/')
  server_info_seq=$(echo $rippled_server_info | sed -E 's/.*seq\":(.*)\},\"validation_quorum.*/\1/')
  echo "$server_info_time $server_info_seq" >> ie-tech-challenge.csv
}

# poll for data and update graph
while $(extract_data_to_csv)
do
  # re-generate graph
    $(gnuplot ./ie-tech-challenge.p)
    sleep 4;
done
```

### How script works
The script gets the server info which is then parsed to extract the time and verified_ledger seq into a csv file. Every 4 seconds the server info is retrieved and a graph is updated using gnuplot. Below is how the graph gets plotted i.e. contents of the `ie-tech-challenge.p` reference in the script above.

```
# ie-tech-challenge.p

# set the output
set terminal png size 2000,2000
set output 'ie-tech-challenge.png'

# set the timeformat
set timefmt '%Y-%b-%d %H:%M:%S'

# ranges
# set autoscale   # let gnuplot determine ranges

# set x axis
set xlabel 'time'
set xdata time
set format x '%Y-%b-%d %H:%M:%S'

# set y axis
set ylabel 'seq'

# plot
plot 'ie-tech-challenge.csv' using 1:3 title 'rippled server info' with lines
```

### Polling interval choice
According to the Ripple website and [YouTube channel](https://www.youtube.com/watch?v=TezY4rLd_Qc), the XRP ledger closes between 3.2 and 4 seconds. I conducted a polling duration script to run every second to understand how long it takes a ledger to close. It took approximately 4 seconds so I decided to poll every 4 seconds in my script to capture as much information as possible.

### Result summary
It takes approximately 4 seconds for a ledger to close. The script polls every 4 seconds but the sequence number skips a sequence. The graph plotted from the server info response is a *mostly* linear graph.

### Time variation in ledger
The XRP Ledger uses deterministic rules which causes the variation of time between new ledgers, therefore whichever transaction comes in first according to the sorting rules succeeds, and whichever conflicting transaction comes second fails. This is why, the majority of the time, the sequence numbers are sequential. The variation can take longer than usual due to the communication or network failure etc.

## Bonus Q1
*skipped*

## Bonus Q2
**There are some other (better) ways that you could use the ripple API to find how long each ledger took to close/validate. Using the API documentation, find. and describe on of these methods (you don’t need to actually implement it).**

The first time the server info is gotten, there are no information regarding the minimum, or maximum, or average amount of time it takes for a ledger too close. However, from the server info result, for each ledger[a request can be made to the more information about the ledger](https://xrpl.org/ledger.html) specifically `ledger.parent_time` and `ledger.time`.
From the response, we set the minimum, maximum and average to equal the different between the two time for the first ledger `ledger.close_time = ledger.time - ledger.parent_time`. Additional we’ll keep a count of how many ledgers gotten so far `total_ledger`.
For each new ledger other than the first, the minimum, maximum and average are calculated using the following rules:
* if `ledger.close_time` is less than the current minimum, the minimum time is updated
* if `ledger.close_time` is greater than the current maximum, the maximum time is updated
* the average involves a bit more of a calculation i.e. `ledger_average_time = ((ledger_average_time * total_ledger) + ledger.close_time)/ (total_ledger + 1)` and the `total_ledger` is incremented