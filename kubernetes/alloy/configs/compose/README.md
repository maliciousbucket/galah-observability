# Alloy Compose

This compose project is used for testing the Alloy Kubernetes configurations and debugging issues with modules.

## Environment Variables

> [!NOTE]
> Any additional addresses / ports must also be configured with both the Alloy chart values file and the Kustomization file

| Variable         | Description                                        | Default                                        |
|------------------|----------------------------------------------------|------------------------------------------------|
| METRICS_ENDPOINT | Prometheus remote write address to send metrics to | http://nginx.gateway.svc:9090/api/v1/push      |
| LOGS_ENDPOINT    | Loki http push address                             | http://nginx.gateway.svc:3100/loki/api/v1/push |
| TRACES_ENDPOINT  | Tempo GRPC listen address                          | http://nginx.gateway.svc:3205                  |

### Provider

| Variable                         | Description                                           | Default |
|----------------------------------|-------------------------------------------------------|---------|
| BASIC_AUTH_USERNAME              | Common username for basic auth                        | null    |
| BASIC_AUTH_PASSWORD              | Common password for basic auth                        | null    |
| BASIC_AUTH_PASSWORD_FILE         | Common password file for basic auth                   | null    |
| METRICS_BASIC_AUTH_PASSWORD_FILE | Password File for basic auth with Mimir or Prometheus | null    |
| METRICS_BASIC_AUTH_PASSWORD      | Password for basic auth with Mimir or Prometheus      | null    |
| METRICS_BASIC_AUTH_USERNAME      | Username for basic auth with Mimir or Prometheus      | null    |
| LOGS_BASIC_AUTH_PASSWORD_FILE    | Password File for basic auth with Loki                | null    |
| LOGS_BASIC_AUTH_PASSWORD         | Password for basic auth with Loki                     | null    |
| LOGS_BASIC_AUTH_USERNAME         | Username for basic auth with Loki                     | null    |
| TRACES_BASIC_AUTH_USERNAME       | Username for basic auth with tempo                    | null    |
| TRACES_BASIC_AUTH_PASSWORD       | Password for basic auth with Tempo                    | null    |


### Collectors

#### Prometheus

| Variable            | Description                                                                                  | Default |
|---------------------|----------------------------------------------------------------------------------------------|---------|
| PROM_LISTEN_ADDRESS | The address to listen on for Prometheus metrics sent over HTTP (remote write / push gateway) | ""      |
| PROM_LISTEN_PORT    | The port to listen on for Prometheus metrics sent over HTTP                                  | 9009    |


#### Loki

[//]: # (TODO: Adjust in alloy)
> [!NOTE]
> Logs sent over GRPC should be targeted at the [OTLP_GRPC endpoint](#otlp)

| Variable            | Description                                 | Default |
|---------------------|---------------------------------------------|---------|
| LOKI_LISTEN_ADDRESS | The address to listen on for HTTP Loki logs | ""      |
| LOKI_LISTEN_PORT    | The port to listen on for HTTP Loki Logs    | 8080    |


#### OTLP

Uses the Alloy [Otelcol OTLP Receiver component](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.receiver.otlp/)

> [!NOTE]
> Any changes to the GRPC transport must also be configured the Alloy chart values file and the Kustomization file

| Variable            | Description                                                                 | Default        |
|---------------------|-----------------------------------------------------------------------------|----------------|
| OTLP_GRPC_ENDPOINT  | The GRPC endpoint to listen on for Open Telemetry Logs, Metrics, and Traces | "0.0.0.0:4317" |
| OTLP_GRPC_TRANSPORT | The transport used for the OTLP GRPC endpoint                               | "tcp"          |
| OTLP_HTTP_ENDPOINT  | The HTTP endpoint to listen on for Open Telemetry Logs, Metrics, and Traces | "0.0.0.0:4318" |
| METRICS_URL_PATH    | The path to listen on for HTTP Open Telemetry Metrics                       | "/v1/metrics"  |
| LOGS_URL_PATH       | The path to listen on for HTTP Open Telemetry Metrics                       | "/v1/logs"     |
| TRACES_URL_PATH     | The path to listen on for HTTP Open Telemetry Metrics                       | "/v1/traces"   |


#### Jaeger

Uses the Alloy [Otelcol Jaeger receiver component](https://grafana.com/docs/alloy/latest/reference/components/otelcol/otelcol.receiver.jaeger/).



> [!NOTE]
> Any changes to the GRPC transport must also be configured the Alloy chart values file and the Kustomization file

| Variable                       | Description                    | Default         |
|--------------------------------|--------------------------------|-----------------|
| JAEGER_GRPC_ENDPOINT           | Jaeger GRPC endpoint           | "0.0.0.0:14520" |
| JAEGER_GRPC_TRANSPORT          | Jaeger GRPC transport          | "tcp"           |
| JAEGER_THRIFT_HTTP_ENDPOINT    | Jaeger thrift HTTP endpoint    | "0.0.0.0:14268" |
| JAEGER_THRIFT_BINARY_ENDPOINT  | Jaeger thrift binary endpoint  | "0.0.0.0:6832"  |
| JAEGER_THRIFT_COMPACT_ENDPOINT | Jaeger thrift compact endpoint | "0.0.0.0:6831"  |


#### Zipkin

| Variable        | Description                                | Default        |
|-----------------|--------------------------------------------|----------------|
| ZIPKIN_ENDPOINT | The address to listen on for Zipkin traces | "0.0.0.0:9411" |

