#!/bin/bash

parse_plot()
{

#Command to parse "hadoop dfsadmin -report" output : (needs improvement)
cmd="ssh hdfs@app310.glam.colo hadoop dfsadmin -report   | egrep -w 'Hostname|DFS Used:' | grep -v 'Non' | tail -n +2 | sed  's/:[[:space:]][0-9]*[[:space:]]/ /g'  | sed 's/:[[:space:]]/ /g' | sed 's/[()]//g' | sed 's/ TB//g' | sed -e 's/DFS Used//g' | tr '\n' ' '  | sed 's/Hostname /,/g'  |tr ',' '\n' | sed 's/  /\t/g' |  tail -n +2 "

#Run hadoop dfs report command
$cmd > $1

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

mail_alert()
{
  mail -s "HDFS Balancer Report (COLO)" -A $before_graph -A $after_graph $mail_recepients  << EOM
Line one.
Line two.
Line three.
EOM
}

cluster_name=COLO
HOME=/home/karank/scripts
today=$(date +"%m-%d-%y")
plot_input_before=$HOME/dfs_before.out
plot_input_after=$HOME/dfs_after.out
before_graph=before_$today.jpg
after_graph=after_$today.jpg
thresh=40

mail_recepients='karank@glam.com'

#Invoke parse_plot function to create graph before HDFS balancer runs
parse_plot $plot_input_before $before_graph

#Hadoop Balancer command
hadoop balancer -threshold $thresh

# Check if balancer ran sucessfully
if [ $? -eq 0 ]
then
        endTime=$(date +"%x_%T")
        echo -e " HDFS Balancer ran successfully ...... "
	#Invoke parse_plot function to create graph after HDFS balancer runs
	parse_plot $plot_input_after $after_graph

else
        endTime=$(date +"%x_%T")
        echo -e " HDFS Balancer failed .... "
fi

#Invoke parse_plot function to create graph after HDFS balancer runs
parse_plot $plot_input_after $after_graph
mail_alert
