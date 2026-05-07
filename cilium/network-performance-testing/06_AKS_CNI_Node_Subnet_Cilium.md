# Azure CNI powered by Cilium - Node Subnet - Native Routing Performance Test

## Test Setup

| Parameter | Value |
| --- | --- |
| AKS Kubernetes version | 1.35.1 |
| Node SKUs | Standard_D4das_v5 (4 vCPU, 16 GB RAM), Standard_D4ds_v5 (4 vCPU, 16 GB RAM) |
| Networking mode | Azure CNI Node Subnet + eBPF Host Routing |
| Cilium version | 1.18.6 |
| Routing mode | Native |
| Encapsulation protocol | None |
| Encryption | None |
| Test tools | iperf3, netperf |
| Test duration | 30 seconds |

### Cilium configuration check

```bash
kubectl -n kube-system exec -it ds/cilium -- cilium status | grep -E "Masquerading|Routing|Encryption"

KubeProxyReplacement:    True   [eth0   10.224.0.113 fe80::72a8:a5ff:fe81:11be (Direct Routing)]
Routing:                 Network: Native   Host: BPF
Masquerading:            BPF (ip-masq-agent)   [eth0]   10.224.0.0/16  [IPv4: Enabled, IPv6: Disabled]
Encryption:              Disabled
```

## Tests

### TCP and UDP throughput tests using iperf3

```bash
# TCP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 -P 4

[SUM]   0.00-30.01  sec  24.7 GBytes  7.07 Gbits/sec  5924             sender
[SUM]   0.00-30.01  sec  24.7 GBytes  7.07 Gbits/sec                   receiver
```

```bash
# UDP throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -u -b 10G -t 30

[ ID] Interval           Transfer     Bitrate         Jitter    Lost/Total Datagrams
[  5]   0.00-30.00  sec  4.36 GBytes  1.25 Gbits/sec  0.000 ms  0/3346278 (0%)  sender
[  5]   0.00-30.00  sec  4.35 GBytes  1.25 Gbits/sec  0.015 ms  2999/3346271 (0.09%)  receiver
```

```bash
# Bidirectional throughput:
kubectl exec -n netperf -it netperf-client -- iperf3 -c iperf3-server -t 30 --bidir

[ ID][Role] Interval           Transfer     Bitrate         Retr
[  5][TX-C]   0.00-30.00  sec  22.6 GBytes  6.46 Gbits/sec  1381             sender
[  5][TX-C]   0.00-30.00  sec  22.6 GBytes  6.46 Gbits/sec                  receiver
[  7][RX-C]   0.00-30.00  sec  5.05 GBytes  1.44 Gbits/sec  292             sender
[  7][RX-C]   0.00-30.00  sec  5.04 GBytes  1.44 Gbits/sec                  receiver
```

### TCP and UDP latency tests using netperf

```bash
# TCP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
104          123.29       5237         158          29.07        8100.974
```

```bash
# UDP latency:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t UDP_RR -l 30 -- -O min_latency,mean_latency,max_latency,p99_latency,stddev_latency,transaction_rate

Minimum      Mean         Maximum      99th         Stddev       Transaction
Latency      Latency      Latency      Percentile   Latency      Rate
Microseconds Microseconds Microseconds Latency      Microseconds Tran/s
                                       Microseconds
108          125.30       3174         161          23.17        3540.191
```

```bash
# TCP stream:
kubectl exec -n netperf -it netperf-client -- netperf -H netperf-server -t TCP_STREAM -l 30

Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    30.00    8390.99
```
