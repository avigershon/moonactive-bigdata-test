# Moon Active Big Data test

We have a stream of player events being written to kafka, each message in the topic consists of a JSON object with the following schema:
* user_id - unique user id
* event - event name e.g. "login","build","attack"
* time - time of event
* ip
* params - JSON encoded values specific to this event type

## Task definition
Your task is to write a consumer which processes these messages and writes them to HBase in a way that will support performing the following queries over HBase efficiently:
* Tech support want to query a time range of events for a specific player, they would like to get all the players events inside the defined time range.
* Batch jobs that transform the data and write to an external DB. These jobs need to read the data of a full day.

## Solution

When hbase stores rows, it sorts them by row key in lexicographic order. There is effectively a single index per table, which is the row key. All other queries result in a full table scan, which will be far, far slower.

In our case, the two queries are different. One query a specific player and the other one needs to read data of a full day.
When dealing with a situation like this where there is no perfect row key, there are two ways to solve this problem:

* Denormalization -
  Use two tables, each with a row key appropriate to one of the queries. This is a good solution, because it results in a robust, scalable system.

* Query and filter -
  Use one query that underperforms because we are filtering a large number of rows. This is not normally a good solution, because it results in a less scalable system that could easily deteriorate as usage increases.

I've decided to go with denormalization option and I created two hbase tables:
* moonactiveplayers - Row Key = user_id#time
* moonactivedaily - Row Key = time#user_id (added user_id to avoid hotspotting)

## Implementation

Kafka -> KSQL (For denormalization) -> Kafka Connect -> HBase Table

* A continuous query in KSQL duplicate the source topic
* Two hbase sink connectors consume rows from moonactiveplayers and moonactivedaily topics and write to the relevant tables

Source code of the hbase sink connector available at https://github.com/nishutayal/kafka-connect-hbase

```bash

# Bootstrap all services on an existing kubernetes cluster
./bootstrap-gcp.sh

# create hbase tables
kubectl exec -it hbase-hbase-rs-0 -- /opt/hbase/bin/hbase shell

create 'moonactiveplayers', 'd'

create 'moonactivedaily', 'd'

# Push events to the source topic moonactivetest
export POD_NAME=$(kubectl get pods --namespace default -l "name=kafka-client" -o jsonpath="{.items[0].metadata.name}")

kubectl -n default exec -ti $POD_NAME -- /usr/bin/kafka-console-producer --broker-list kafka-headless:9092 --topic moonactivetest

# Push new events
{"user_id": 1, "event": "login", "time": 20180101, "ip": "0.0.0.0", "params": "{\"key1\": \"value\", \"key2\": \"value\"}"}

{"user_id": 1, "event": "logout", "time": 20180102, "ip": "0.0.0.0", "params": "{\"key3\": \"value\", \"key4\": \"value\"}"}

```
