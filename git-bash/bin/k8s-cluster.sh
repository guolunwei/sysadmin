#!/bin/bash

set -e

case $1 in
  start)
    echo "Starting k8s cluster..."
    for i in nginx-lb node{3..1} master{3..1}; do
      vm start "$i"
    done
    ;;
  stop)
    echo "Stopping k8s cluster..."
    for i in nginx-lb node{3..1} master{3..1}; do
      vm stop "$i"
    done
    ;;
esac
