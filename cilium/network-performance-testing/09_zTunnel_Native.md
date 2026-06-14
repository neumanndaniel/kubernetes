# Cilium - Native Routing + ztunnel Encryption Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | BYOCNI |
| Cilium version | 1.19.3 |
| Routing mode | Native |
| Encapsulation protocol | None |
| Encryption | ztunnel |
| Test tools | iperf3, netperf |
| Test duration | 30 seconds |

> [!NOTE]
> Additional Azure resource setup required: [An experiment – Enable Cilium native routing on Azure Kubernetes Service BYOCNI – Part 3](https://www.danielstechblog.io/an-experiment-enable-cilium-native-routing-on-azure-kubernetes-service-byocni-part-3/)
>
> - BGP Route Reflector VM using Ubuntu + FRR
> - Azure Route Server

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
encryption:
  enabled: true
  type: ztunnel
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

### Cilium configuration check

```bash
kubectl -n kube-system exec -it ds/cilium -- cilium status | grep -E "Masquerading|Routing|Encryption"
KubeProxyReplacement:    True   [eth0   10.10.0.11 fe80::7e1e:52ff:fe37:cb1e (Direct Routing)]
Routing:                 Network: Native   Host: BPF
Masquerading:            BPF   [eth0]   100.64.0.0/10  [IPv4: Enabled, IPv6: Disabled]
Encryption:              Ztunnel
```

## Tests

### TCP and UDP throughput tests using iperf3

```bash
# TCP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 -P 4

[SUM]   0.00-30.00  sec  41.8 GBytes  12.0 Gbits/sec  4376             sender
[SUM]   0.00-30.02  sec  41.7 GBytes  11.9 Gbits/sec                   receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  6.78 GBytes  1.94 Gbits/sec  0.000 ms  0/5030987 (0%)  sender
[  5]   0.00-30.04  sec  6.55 GBytes  1.87 Gbits/sec  0.006 ms  173750/5030987 (3.5%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  36.6 GBytes  10.5 Gbits/sec  163             sender
[  5][TX-C]   0.00-30.04  sec  36.6 GBytes  10.5 Gbits/sec                  receiver
[  7][RX-C]   0.00-30.00  sec  31.9 GBytes  9.13 Gbits/sec  840             sender
[  7][RX-C]   0.00-30.04  sec  31.9 GBytes  9.11 Gbits/sec                  receiver
```

### TCP and UDP latency tests using netperf

```bash
# TCP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
209          261.42       5807         384          81.39        3821.735
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
129          154.08       4959         195          44.51        6481.321
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.01    6663.76
```
