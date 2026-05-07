# Azure CNI powered by Cilium - Overlay - Native Routing Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | Azure CNI Overlay + eBPF Host Routing |
| Cilium version | 1.18.6 |
| Routing mode | Native |
| Encapsulation protocol | None |
| Encryption | None |
| Test tools | iperf3, netperf |
| Test duration | 30 seconds |

### Cilium configuration check

```bash
kubectl -n kube-system exec -it ds/cilium -- cilium status | grep -E "Masquerading|Routing|Encryption"

KubeProxyReplacement:    True   [eth0   10.224.0.5 fe80::7eed:8dff:fe75:53e6 (Direct Routing)]
Routing:                 Network: Native   Host: BPF
Masquerading:            BPF (ip-masq-agent)   [eth0]   10.244.0.0/16  [IPv4: Enabled, IPv6: Disabled]
Encryption:              Disabled
```

## Tests

### TCP and UDP throughput tests using iperf3

```bash
# TCP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 -P 4

[SUM]   0.00-30.00  sec  22.5 GBytes  6.44 Gbits/sec  2095             sender
[SUM]   0.00-30.00  sec  22.5 GBytes  6.44 Gbits/sec                   receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  4.51 GBytes  1.29 Gbits/sec  0.000 ms  0/3460556 (0%)  sender
[  5]   0.00-30.00  sec  4.50 GBytes  1.29 Gbits/sec  0.006 ms  6580/3460502 (0.19%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  21.0 GBytes  6.02 Gbits/sec  706             sender
[  5][TX-C]   0.00-30.00  sec  21.0 GBytes  6.02 Gbits/sec                  receiver
[  7][RX-C]   0.00-30.00  sec  5.96 GBytes  1.71 Gbits/sec  495             sender
[  7][RX-C]   0.00-30.00  sec  5.95 GBytes  1.70 Gbits/sec                  receiver
```

### TCP and UDP latency tests using netperf

```bash
# TCP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
307          333.18       4840         384          39.75        2999.744
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
314          339.52       5235         391          38.01        2943.729
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.00    9809.07
```
