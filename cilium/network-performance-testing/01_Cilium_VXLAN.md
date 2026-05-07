# Cilium - VXLAN Encapsulation Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | BYOCNI |
| Cilium version | 1.19.3 |
| Routing mode | Tunnel |
| Encapsulation protocol | VXLAN |
| Encryption | None |
| Test tools | iperf3, netperf |
| Test duration | 30 seconds |

### BYOCNI - Cilium specific configuration parameters

```YAML
aksbyocni:
  enabled: true
bpf:
  hostLegacyRouting: false
  masquerade: true
ciliumEndPointSlice:
  enabled: true
cni:
  exclusive: true
disableEndPointCRD: false
ipam:
  operator:
    clusterPoolIPv4PodCIDRList:
      - 100.64.0.0/10
kubeProxyReplacement: true
routingMode: tunnel
socketLB:
  hostNamespaceOnly: true
tunnelProtocol: vxlan
```

## Tests

### TCP and UDP throughput tests using iperf3

```bash
# TCP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 -P 4

[SUM]   0.00-30.00  sec  26.6 GBytes  7.61 Gbits/sec  9253             sender
[SUM]   0.00-30.00  sec  26.5 GBytes  7.60 Gbits/sec                   receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  5.39 GBytes  1.54 Gbits/sec  0.000 ms  0/4143624 (0%)  sender
[  5]   0.00-30.00  sec  5.21 GBytes  1.49 Gbits/sec  0.009 ms  141431/4143607 (3.4%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  13.4 GBytes  3.84 Gbits/sec  1965             sender
[  5][TX-C]   0.00-30.00  sec  13.4 GBytes  3.84 Gbits/sec                  receiver
[  7][RX-C]   0.00-30.00  sec  8.46 GBytes  2.42 Gbits/sec  359             sender
[  7][RX-C]   0.00-30.00  sec  8.45 GBytes  2.42 Gbits/sec                  receiver
```

### TCP and UDP latency tests using netperf

```bash
# TCP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
133          164.91       6806         219          64.30        6056.582
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
134          164.42       9518         226          72.01        6077.425
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.00    6926.50
```
