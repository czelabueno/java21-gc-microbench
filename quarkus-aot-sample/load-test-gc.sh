#!/usr/bin/env bash

# Validating GC type as argument. If not provided, exit
if [[ "$1" != "Parallel" && "$1" != "G1" && "$1" != "ZGC" && "$1" != "GenerationalZGC" ]]; then
    echo "Invalid argument. Please provide one of the following JVM GC values: Parallel, G1, ZGC, GenerationalZGC"
    exit 1
fi

# Create files to store stats in
rm -f JDK_21_$1.txt JDK_21_$1_metrics.txt
touch "JDK_21_$1.txt" "JDK_21_$1_metrics.txt"

# Let's stress test and get stats
echo -ne "Stress Testing..."

JAR_PATH="target/quarkus-aot-sample-1.0.0-SNAPSHOT-runner.jar"
PID=$(ps aux | grep "[${JAR_PATH:0:1}]${JAR_PATH:1}" | awk '{print $2; exit}')

hey -z 20s -c 4 http://localhost:8080/community | tee JDK_21_$1.txt &

# Collecting Max RSS stat during stress test
MAX_RSS=0
while [ -n "$(pgrep hey)" ]; do
    echo -ne "#"
    RSS=`ps -o rss ${PID} | tail -n1`
    RSS=`bc <<< "scale=1; ${RSS}/1024"`
    if (( $(echo "$RSS > $MAX_RSS" | bc -l) )); then
        MAX_RSS=$RSS
    fi
    sleep 1
done

# Collecting throughput stat
JDK_GC_REQS=`cat JDK_21_$1.txt | grep -Eo '[[:space:]]+Requests/sec:[[:space:]][0-9]+.[0-9]+' | awk '{print $2}'`

# Collecting latency stat
JDK_GC_LAT=`cat JDK_21_$1.txt | grep --color=auto -Eo '99% in [0-9]+.[0-9]+ secs' | sed 's/99% in //' | sed 's/ secs//' | awk '{printf "%d", $1*1000000}' `

# Collecting total request sent
JDK_GC_RESP=`cat JDK_21_$1.txt | grep -Eo '[[:space:]]\[200\][[:space:]]+[0-9]+' | awk '{print $2}'`

# Print stats report
echo -e "\033[32mPrinting Stats report for $1 GC...\033[0m"

echo -e "Performance metrics for JDK $1 Garbage Collector\n" >> JDK_21_$1_metrics.txt
echo -e "PID ${PID}: MAX RSS ${MAX_RSS}M" >> JDK_21_$1_metrics.txt
echo "Throughput req/s: $JDK_GC_REQS" >> JDK_21_$1_metrics.txt
echo "Latency of 99% of Requests: $JDK_GC_LAT μs(microseconds)" >> JDK_21_$1_metrics.txt
echo "Total responses: $JDK_GC_RESP [200 OK]" >> JDK_21_$1_metrics.txt

cat JDK_21_$1_metrics.txt