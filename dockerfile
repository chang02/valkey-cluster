FROM valkey/valkey:8.1

RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

COPY start-cluster.sh /start-cluster.sh

RUN chmod +x /start-cluster.sh

# Valkey 서버 노드 포트
EXPOSE 6000-6005
# Valkey 클러스터 버스 포트
EXPOSE 16000-16005

ENTRYPOINT ["/start-cluster.sh"]