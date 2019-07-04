# set the output
set terminal png size 2000,2000
set output 'ie-tech-challenge.png'

# set the timeformat
set timefmt '%Y-%b-%d %H:%M:%S'

# set x axis
set xlabel 'time'
set xdata time
set format x '%Y-%b-%d %H:%M:%S'

# set y axis
set ylabel 'seq'

# plot
plot 'ie-tech-challenge.csv' using 1:3 title 'rippled server ledger' with lines