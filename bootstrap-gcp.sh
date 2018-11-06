#!/bin/bash

echo "installing helm tiller and client"
bash ./setup-gcp.sh

echo "default installation storageClass and role binding for dashboard admin"
bash ./setup-gcp.sh --chart charts/default

echo "installing hbase"
bash ./setup-gcp.sh --chart charts/hbase

echo "installing kafka"
bash ./setup-gcp.sh --chart charts/kafka

echo "installing ksql"
bash ./setup-gcp.sh --chart charts/ksql

echo "installing kafka-connect"
bash ./setup-gcp.sh --chart charts/kafka-connect

echo "installing kafka-client"
bash ./setup-gcp.sh --chart charts/kafka-client
