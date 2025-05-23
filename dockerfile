FROM valkey/valkey:8.1

RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

COPY start-cluster.sh /start-cluster.sh

RUN chmod +x /start-cluster.sh

ENTRYPOINT ["/start-cluster.sh"]