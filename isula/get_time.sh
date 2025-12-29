#!/bin/bash

function getTiming() {
    local start=$1
    local end=$2

    local start_s=$(echo $start | cut -d '.' -f 1 | tr -d -c '0-9 n')
    local start_ns=$(echo $start | cut -d '.' -f 2 | tr -d -c '0-9 n')

    local end_s=$(echo $end | cut -d '.' -f 1 | tr -d -c '0-9 n')	
    local end_ns=$(echo $end | cut -d '.' -f 2 | tr -d -c '0-9 n')

    while [ $(echo ${start_ns:0:1}) == 0 ]
    do
        start_ns=$(echo ${start_ns#*0})
    done

    while [ $(echo ${end_ns:0:1}) == 0 ]
    do
        end_ns=$(echo ${end_ns#*0})
    done

    local sum_start_ms=$(($start_s*1000+$start_ns/1000000))
    local sum_end_ms=$(($end_s*1000+$end_ns/1000000))
    time=$(($sum_end_ms-$sum_start_ms))

    echo "${time}"
}
