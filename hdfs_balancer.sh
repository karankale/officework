#!/bin/bash

parse_plot()
{

#Command to parse "hadoop dfsadmin -report" output : (needs improvement)
hadoop dfsadmin -report   | egrep -w 'Hostname|DFS Used:' | grep -v 'Non' | tail -n +2 | sed  's/:[[:space:]][0-9]*[[:space:]]/ /g'  | sed 's/:[[:space:]]/ /g' | sed 's/[()]//g' | sed 's/ TB//g' | sed -e 's/DFS Used//g' | tr '\n' ' '  | sed 's/Hostname /,/g'  |tr ',' '\n' | sed 's/  /\t/g' |  tail -n +2 > $1

#GNU plot script
gnuplot <<-EOF
reset
set terminal jpeg size 1024,768
set output "$2"
set xlabel "hosts"
set ylabel "DFS Used in TB"
set yrange [0:11]
set boxwidth 0.25
set style fill solid
set xtic rotate by -90 scale 0 font ",8"
plot "$1" using (column(0)):2:xtic(1) ti col with boxes
EOF

}

HOME=/var/lib/hadoop-hdfs
today=$(date +"%m-%d-%y")
plot_input_before=$HOME/scripts/dfs_before.out
plot_input_after=$HOME/scripts/dfs_after.out
before_graph=before_$today.jpg
after_graph=after_$today.jpg
thresh=40

#Invoke parse_plot function to create graph before HDFS balancer runs
parse_plot $plot_input_before $before_graph

#Hadoop Balancer command
#hadoop balancer -threshold $thresh

#Invoke parse_plot function to create graph after HDFS balancer runs
parse_plot $plot_input_after $after_graph

