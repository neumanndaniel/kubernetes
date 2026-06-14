# Cilium - Geneve Encapsulation + ztunnel Encryption Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | BYOCNI |
| Cilium version | 1.19.3 |
| Routing mode | Tunnel |
| Encapsulation protocol | Geneve |
| Encryption | ztunnel |
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
encryption:
  enabled: true
  type: ztunnel
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

[SUM]   0.00-30.00  sec  33.4 GBytes  9.55 Gbits/sec  4024             sender
[SUM]   0.00-30.04  sec  33.3 GBytes  9.53 Gbits/sec                   receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  4.96 GBytes  1.42 Gbits/sec  0.000 ms  0/3812528 (0%)  sender
[  5]   0.00-30.04  sec  4.75 GBytes  1.36 Gbits/sec  0.008 ms  167142/3812528 (4.4%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  15.5 GBytes  4.44 Gbits/sec   78             sender
[  5][TX-C]   0.00-30.04  sec  15.5 GBytes  4.43 Gbits/sec                  receiver
[  7][RX-C]   0.00-30.00  sec  13.2 GBytes  3.78 Gbits/sec  166             sender
[  7][RX-C]   0.00-30.04  sec  13.2 GBytes  3.77 Gbits/sec                  receiver
```

### TCP and UDP latency tests using netperf

```bash
# TCP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
239          329.84       13335        839          227.80       3029.582
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
143          189.12       10420        426          181.81       5283.423
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.02    4608.32
```
