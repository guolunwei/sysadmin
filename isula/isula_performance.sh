#!/bin/bash

source ./get_time.sh

container_num=100
image=openeuler/openeuler:20.09
client=isula

function create_containers() {
	t1=$(date +%s.%N)
	for i in $(seq 1 $container_num)
	do
		$client create --name container${i} --net none ${image} &
	done
	wait

	t2=$(date +%s.%N)
	create_time=$(getTiming ${t1} ${t2})
}

function start_containers() {
    t1=$(date +%s.%N)
    for i in $(seq 1 $container_num)
    do
        $client start container${i} &
    done
    wait

    t2=$(date +%s.%N)
    start_time=$(getTiming ${t1} ${t2})
}

function stop_containers() {
    t1=$(date +%s.%N)
    for i in $(seq 1 $container_num)
    do
        $client stop -t 0 container${i} &
    done
    wait

    t2=$(date +%s.%N)
    stop_time=$(getTiming ${t1} ${t2})
}

function remove_containers() {
    t1=$(date +%s.%N)
    for i in $(seq 1 $container_num)
    do
        $client rm container${i} &
    done
    wait

    t2=$(date +%s.%N)
    remove_time=$(getTiming ${t1} ${t2})
}

create_containers
sleep 3
start_containers
sleep 3
stop_containers
sleep 3
remove_containers

echo "Sum time of create $container_num containers: ${create_time}ms"
echo "Sum time of start $container_num containers: ${start_time}ms"
echo "Sum time of stop $container_num containers: ${stop_time}ms"
echo "Sum time of remove $container_num containers: ${remove_time}ms"
