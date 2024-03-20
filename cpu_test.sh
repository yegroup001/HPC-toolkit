#!/bin/bash
        THREAD=64
        MAX_CORE_FREQ=2500
        MAX_UNCORE_FREQ=24

        mkdir cpu_test
        cd cpu_test
        dir="$PWD"
        touch memory_bandwidth.txt
        touch memory_latency.txt
        touch power_freq.txt
        #touch stress-ng_output.txt
        sudo apt install stress-ng
        sudo apt install powerstat
        # Memory buswidth test
        sudo apt install gfortran
        git clone https://github.com/yegroup001/STREAM
        cd STREAM
        make
        echo "Now starting memory buswidth test!"
        for freq in $(seq 800 100 ${MAX_CORE_FREQ}); do
            for thread in $(seq 0 63); do
                sudo cpufreq-set -g userspace -c $thread
                sudo cpufreq-set -f ${freq}MHz -c $thread
        done
        if [ $? -eq 0 ]; then
                echo "Setting core frequency ${freq}MHz succeeded!"
        else
                echo "\033[31m Error:\033[0m Setting core frequency ${freq}MHz failed!"
                exit 1
        fi
        for uncore in $(seq 8 2 $MAX_UNCORE_FREQ); do
                hex_uncore=$(printf "%02x" "$uncore")
                hex_value="0x${hex_uncore}${hex_uncore}"
                sudo wrmsr -a 0x620 $hex_value

        if [ $? -eq 0 ]; then
                echo "Setting uncore frequency ${uncore}00MHz succeeded!"
        else
                echo "\033[31m Error:\033[0m Setting uncore frequency ${uncore}00MHz failed!"
                exit 1
        fi
        echo "memory_bandwidth test start"
        ./stream_c.exe | awk 'NR==27 {print $2}' >> $dir/memory_bandwidth.txt
        echo "memory_bandwidth test done"
        sleep 0.5s
                done
        done

        #latency_test
#       cd ..
#       mkdir mlc
#       cd mlc
#       wget https://downloadmirror.intel.com/793041/mlc_v3.11.tgz
#       tar xvf mlc_v3.11.tgz
#       cd Linux
#       echo "Now starting memory latency test!"
#       for freq in $(seq 800 100 ${MAX_CORE_FREQ}); do
#           for thread in $(seq 0 63); do
#              sudo cpufreq-set -g userspace -c $thread
#                sudo cpufreq-set -f ${freq}MHz -c $thread
#        done
#        if [ $? -eq 0 ]; then
#                echo "Setting core frequency ${freq}MHz succeeded!"
#        else
#                echo "\033[31m Error:\033[0m Setting core frequency ${freq}MHz failed!"
#                exit 1
#        fi
#    for uncore in $(seq 8 2 $MAX_UNCORE_FREQ); do
#             hex_uncore=$(printf "%02x" "$uncore")
#              hex_value="0x${hex_uncore}${hex_uncore}"
#               sudo wrmsr -a 0x620 $hex_value
#
#       if [ $? -eq 0 ]; then
#                echo "Setting uncore frequency ${uncore}00MHz succeeded!"
#        else
#                echo "\033[31m Error: \033[0m Setting uncore frequency ${uncore}00MHz failed!"
#                exit 1
#       fi
#               echo "latency_test start"
#               sudo ./mlc --latency_matrix | awk 'NR==10 {print $2}' >> $dir/memory_latency.txt
#               echo "latency_test done"
#       done
#       done


        #power_freq test
        echo "Now starting power_freq test! "
        (stress-ng -c 64 &> stress_ng_output.txt &) & stress_ng_pid=$!

        for freq in $(seq 800 100 ${MAX_CORE_FREQ}); do
            for thread in $(seq 0 63); do
                sudo cpufreq-set -g userspace -c $thread
                sudo cpufreq-set -f ${freq}MHz -c $thread
        done
        if [ $? -eq 0 ]; then
                echo "Setting core frequency ${freq}MHz succeeded!"
        else
                echo "\033[31m Error:\033[0m Setting core frequency ${freq}MHz failed!"
                exit 1
        fi
        for uncore in $(seq 8 2 $MAX_UNCORE_FREQ); do
                hex_uncore=$(printf "%02x" "$uncore")
                hex_value="0x${hex_uncore}${hex_uncore}"
                sudo wrmsr -a 0x620 $hex_value
        if [ $? -eq 0 ]; then
                echo "Setting uncore frequency ${uncore}00MHz succeeded!"
        else
                echo "\033[31m Error:\033[0m Setting uncore frequency ${uncore}00MHz failed!"
                exit 1
        fi
        echo "power_freq test start"
        RUN_TIME=7
        sudo timeout ${RUN_TIME}s   powerstat -R -c -f | awk 'NR==11 {print $13}' >> $dir/power_freq.txt
        echo "power_freq test stop"
        done
        kill -9 $stress_ng_pid
        done
