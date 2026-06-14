# Cilium - Geneve Encapsulation Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | BYOCNI |
| Cilium version | 1.19.3 |
| Routing mode | Tunnel |
| Encapsulation protocol | Geneve |
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
tunnelProtocol: geneve
```

## Tests

### TCP and UDP throughput tests using iperf3

```bash
# TCP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 -P 4

[SUM]   0.00-30.01  sec  25.2 GBytes  7.22 Gbits/sec  7738             sender
[SUM]   0.00-30.01  sec  25.2 GBytes  7.22 Gbits/sec                   receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  5.44 GBytes  1.56 Gbits/sec  0.000 ms  0/4177289 (0%)  sender
[  5]   0.00-30.00  sec  5.27 GBytes  1.51 Gbits/sec  0.005 ms  129666/4177219 (3.1%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  14.1 GBytes  4.04 Gbits/sec  1330             sender
[  5][TX-C]   0.00-30.00  sec  14.1 GBytes  4.04 Gbits/sec                  receiver
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
133          163.94       11825        259          88.83        6095.122
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
132          160.65       10124        217          62.66        6219.893
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.00    6808.56
```
