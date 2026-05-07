# Cilium - Native Routing + WireGuard Encryption Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | BYOCNI |
| Cilium version | 1.19.3 |
| Routing mode | Native |
| Encapsulation protocol | None |
| Encryption | WireGuard |
| Test tools | iperf3, netperf |
| Test duration | 30 seconds |

### BYOCNI - Cilium specific configuration parameters

```YAML
aksbyocni:
  enabled: false
autoDirectNodeRoutes: false
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
  type: wireguard
  nodeEncryption: true
ipam:
  operator:
    clusterPoolIPv4PodCIDRList:
      - 100.64.0.0/10
ipv4NativeRoutingCIDR: 100.64.0.0/10
kubeProxyReplacement: true
routingMode: native
socketLB:
  hostNamespaceOnly: true
```

## Tests

### TCP and UDP throughput tests using iperf3

```bash
# TCP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 -P 4

[SUM]   0.00-30.00  sec  8.27 GBytes  2.37 Gbits/sec  990             sender
[SUM]   0.00-30.01  sec  8.26 GBytes  2.37 Gbits/sec                  receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  3.61 GBytes  1.03 Gbits/sec  0.000 ms  0/2834923 (0%)  sender
[  5]   0.00-30.00  sec  3.60 GBytes  1.03 Gbits/sec  0.013 ms  7079/2834903 (0.25%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  5.78 GBytes  1.65 Gbits/sec  224             sender
[  5][TX-C]   0.00-30.00  sec  5.78 GBytes  1.65 Gbits/sec                  receiver
[  7][RX-C]   0.00-30.00  sec  1.66 GBytes   477 Mbits/sec   28             sender
[  7][RX-C]   0.00-30.00  sec  1.66 GBytes   476 Mbits/sec                  receiver
```

### TCP and UDP latency tests using netperf

```bash
# TCP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
156          224.47       17696        503          177.76       4448.669
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
150          232.26       9507         600          195.48       4299.827
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.01    2224.60
```
