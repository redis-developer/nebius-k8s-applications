## Description

Redis is the world's fastest in-memory data platform for caching, vector search, real-time context for AI, and modern data workloads. Redis 8.8 brings search, vector similarity search, JSON, time series, and probabilistic data structures together in a single server, so you can build fast apps without stitching together multiple databases.

Key capabilities:
- Sub-millisecond latency for caching and session management
- Vector similarity search for AI apps, including RAG, semantic search, and recommendations
- Full-text search and secondary indexing
- JSON document storage with JSONPath query support
- Time series data with downsampling and aggregation
- Probabilistic data structures, including Bloom filters, Count-Min Sketch, Top-K, and HyperLogLog
- Streams for event-driven architectures
- Pub/Sub messaging

## Short description

Redis is the world's fastest in-memory data platform for caching, vector search, real-time context for AI, and modern data workloads. Run Redis 8.8 on Kubernetes with built-in search, JSON, time series, and vector capabilities.

## Tutorial

This application deploys a standalone Redis 8.8 server as a Kubernetes `StatefulSet` with persistent storage and optional password authentication.

### Prerequisites

- A Nebius Managed Service for Kubernetes cluster (or a Compute VM running K3s).
- A `StorageClass` available in the cluster when persistence is enabled. On K3s, the bundled `local-path` provisioner is used automatically.
- `kubectl` configured to access the target cluster (for post-install verification).

### Deployment steps

1. Open the Redis application in the Nebius web console and click **Deploy**.
2. Select the target Kubernetes cluster.
3. Set the **Application name** and **Namespace**.
4. Configure the installation parameters (see the table below) and submit the form.
5. Wait for the release to reach a healthy state — the Redis pod becomes `Ready` once the `redis-cli ping` probe succeeds.

### Configurable parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.enabled` | Enable password authentication (`requirepass`). | `true` |
| `auth.password` | Password to use. Leave empty to auto-generate a strong password stored in a Secret. | _(generated)_ |
| `persistence.enabled` | Persist data on a PersistentVolume. | `true` |
| `persistence.size` | Size of the data volume. | `10Gi` |
| `persistence.storageClass` | StorageClass for the PVC (empty = cluster default). | `""` |
| `resources.requests.memory` / `resources.requests.cpu` | Guaranteed resources. | `256Mi` / `250m` |
| `resources.limits.memory` / `resources.limits.cpu` | Resource limits. | `1Gi` / `1000m` |
| `redis.maxmemory` | Maximum dataset memory before eviction. | `512mb` |
| `redis.maxmemoryPolicy` | Eviction policy. | `allkeys-lru` |
| `service.type` | Kubernetes Service type. | `ClusterIP` |
| `service.port` | Service port. | `6379` |
| `replicaCount` | Number of StatefulSet replicas. | `1` |

{% note warning %}

When `auth.enabled` is set to `false`, anyone with network access to the Redis service can connect without a password. Keep authentication enabled for any non-trivial deployment.

{% endnote %}

## Usage

After the release is healthy, retrieve the auto-generated password (when `auth.enabled` is `true`):

```bash
kubectl get secret --namespace <namespace> <release-name>-auth \
  -o jsonpath="{.data.redis-password}" | base64 -d
```

### Connect from inside the cluster

The service is reachable at:

```
<release-name>.<namespace>.svc.cluster.local:6379
```

Connect with `redis-cli` from within the pod:

```bash
kubectl exec -it --namespace <namespace> <release-name>-0 -- redis-cli
# then, if auth is enabled:
AUTH <password>
PING        # → PONG
```

### Connect from your local machine

```bash
kubectl --namespace <namespace> port-forward svc/<release-name> 6379:6379
redis-cli -h 127.0.0.1 -p 6379 -a <password>
```

### Connection string format

```
redis://:<password>@<host>:6379/0
```

### Client libraries

Use any standard Redis client, for example:

```python
import redis

client = redis.Redis(
    host="<release-name>.<namespace>.svc.cluster.local",
    port=6379,
    password="<password>",
    decode_responses=True,
)
client.set("hello", "world")
print(client.get("hello"))  # → world
```

## Use cases

- **AI Agents & Agent Memory**: Give AI agents short-term working memory and long-term recall so they can retain session context, user preferences, past decisions, and key facts across turns, sessions, and channels.
- **Semantic Caching for AI Apps**: Cut LLM cost and latency by storing and reusing responses for semantically similar prompts instead of sending every request back to the model.
- **Vector Search for RAG and Semantic Retrieval**: Power RAG and semantic retrieval with fast vector search over embeddings so applications can find the most relevant context for each query.
- **Feature Store for Real-time ML**: Serve machine learning features with sub-millisecond latency for real-time inference while keeping training and serving features consistent across batch, streaming, and real-time pipelines.
- **Session Management for Modern Apps**: Keep application state fast and responsive for modern user experiences with low-latency session storage built for scale.
- **Real-time Analytics & Leaderboards**: Ingest, aggregate, and query live data for analytics, telemetry, and leaderboards with the speed needed for real-time applications.

## Links

[Redis documentation](https://redis.io/docs/latest/)
[Redis source code (GitHub)](https://github.com/redis/redis)
[Official Redis Docker image](https://hub.docker.com/_/redis)
[Redis University (free courses)](https://university.redis.io/)
[Redis command reference](https://redis.io/docs/latest/commands/)

## Legal

Redis 8.x is dual-licensed under the **Redis Source Available License v2 (RSALv2)** and the **Server Side Public License v1 (SSPLv1)**. It is **not** distributed under the Apache 2.0 license.

By using this application you agree to the applicable Redis license terms. See the full license details at [Redis licenses](https://redis.io/legal/licenses/).

The accompanying Helm chart is provided under the terms of the [nebius-k8s-applications repository license](https://github.com/nebius/nebius-k8s-applications/blob/main/LICENSE).
