export POD_NAME=$(kubectl get pods --namespace default -l "name=kafka-client" -o jsonpath="{.items[0].metadata.name}")

export TOPIC=moonactivetest

kubectl -n default exec $POD_NAME -- /usr/bin/kafka-topics --zookeeper kafka-zookeeper:2181 --list

kubectl -n default exec $POD_NAME -- /usr/bin/kafka-topics --zookeeper kafka-zookeeper:2181 --topic $TOPIC --create --partitions 1 --replication-factor 1

kubectl -n default exec $POD_NAME -- /usr/bin/kafka-topics --delete --zookeeper kafka-zookeeper:2181 --topic $TOPIC
