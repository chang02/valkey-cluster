#!/bin/bash

VALKEY_USER=${VALKEY_USER:-myuser}
VALKEY_PASS=${VALKEY_PASS:-myVeryStrongPass}
cat > /valkey.conf <<EOF
bind 0.0.0.0
protected-mode no
user default off
user $VALKEY_USER on >$VALKEY_PASS allcommands allkeys
EOF

# 클러스터 노드 개수
NODE_COUNT=6
BASE_PORT=${BASE_PORT:-7000}
BASE_BUSPORT=${BASE_BUSPORT:-17000}

# 여러 개의 valkey-server 백그라운드 실행
for i in $(seq 0 $(($NODE_COUNT - 1))); do
  port=$(($BASE_PORT + $i))
  bus_port=$(($BASE_BUSPORT + $i))
  data_dir="/data/node-$i"
  mkdir -p $data_dir

  valkey-server /valkey.conf \
    --port $port \
    --dir $data_dir \
    --cluster-enabled yes \
    --cluster-config-file nodes.conf \
    --cluster-node-timeout 5000 \
    --appendonly yes \
    --cluster-announce-ip 127.0.0.1 \
    --cluster-announce-port $port \
    --cluster-announce-bus-port $bus_port \
    > $data_dir/valkey.log 2>&1 &
done

# 모든 노드가 뜰 때까지 대기
for i in $(seq 0 $(($NODE_COUNT - 1))); do
  port=$(($BASE_PORT + $i))
  until valkey-cli -p $port --user $VALKEY_USER --pass $VALKEY_PASS ping; do
    echo "Waiting for Valkey node on port $port..."
    sleep 1
  done
done

sleep 2

# 클러스터 생성
CLUSTER_CREATE_CMD="valkey-cli --cluster create"
for i in $(seq 0 $(($NODE_COUNT - 1))); do
  port=$(($BASE_PORT + $i))
  CLUSTER_CREATE_CMD="$CLUSTER_CREATE_CMD 127.0.0.1:$port"
done
CLUSTER_CREATE_CMD="$CLUSTER_CREATE_CMD --cluster-replicas 1 --cluster-yes --user $VALKEY_USER --pass $VALKEY_PASS"

echo "Creating cluster: $CLUSTER_CREATE_CMD"
eval $CLUSTER_CREATE_CMD

tail -f /dev/null