# Cilium - Native Routing Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | BYOCNI |
| Cilium version | 1.18.6 |
| Routing mode | Native |
| Encapsulation protocol | None |
| Encryption | None |
| Test tools | iperf3, netperf |
| Test duration | 30 seconds |

> [!NOTE]
> Additional Azure resource setup required: [An experiment – Enable Cilium native routing on Azure Kubernetes Service BYOCNI – Part 3](https://www.danielstechblog.io/an-experiment-enable-cilium-native-routing-on-azure-kubernetes-service-byocni-part-3/)
>
> - BGP Route Reflector VM using Ubuntu + FRR
> - Azure Route Server

### Cilium configuration check

```bash
kubectl -n kube-system exec -it ds/cilium -- cilium status | grep -E "Masquerading|Routing|Encryption"

KubeProxyReplacement:    True   [eth0   10.10.0.11 fe80::7eed:8dff:fe77:fb86 (Direct Routing)]
Routing:                 Network: Native   Host: BPF
Masquerading:            BPF   [eth0]   100.64.0.0/10  [IPv4: Enabled, IPv6: Disabled]
Encryption:              Disabled
```

### BYOCNI - Cilium specific configuration parameters

```YAML
aksbyocni:
  enabled: false
autoDirectNodeRoutes: false
bgpControlPlane:
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

[SUM]   0.00-30.00  sec  30.6 GBytes  8.77 Gbits/sec  14233             sender
[SUM]   0.00-30.01  sec  30.6 GBytes  8.77 Gbits/sec                    receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  7.01 GBytes  2.01 Gbits/sec  0.000 ms  0/5349862 (0%)  sender
[  5]   0.00-30.00  sec  6.22 GBytes  1.78 Gbits/sec  0.029 ms  599671/5349752 (11%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  14.2 GBytes  4.07 Gbits/sec  1191             sender
[  5][TX-C]   0.00-30.00  sec  14.2 GBytes  4.07 Gbits/sec                  receiver
[  7][RX-C]   0.00-30.00  sec  10.6 GBytes  3.05 Gbits/sec  1802             sender
[  7][RX-C]   0.00-30.00  sec  10.6 GBytes  3.05 Gbits/sec                  receiver
```

### TCP and UDP latency tests using netperf

```bash
# TCP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
106          127.53       4904         159          34.88        7826.064
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
104          124.68       6032         162          42.82        8005.991
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.00    11497.17
```
