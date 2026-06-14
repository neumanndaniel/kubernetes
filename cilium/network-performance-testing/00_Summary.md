# Cilium - Performance Test Summary

This document provides a summary of the network performance tests conducted on Azure Kubernetes Service (AKS) using Cilium as the Container Network Interface (CNI) plugin. The tests were designed to evaluate the performance of Cilium in different configurations, including VXLAN encapsulation, WireGuard encryption, and native routing modes.

The performance metrics were collected using tools such as iperf3 and netperf, focusing on TCP and UDP throughput, latency, and bidirectional performance. The tests were conducted on Azure Kubernetes Service (AKS) clusters with specific Kubernetes versions and node SKUs to ensure consistency and reliability of the results.

## Results Summary - BYOCNI on Azure Kubernetes Service - Cilium 1.19.3

| Test | VXLAN | VXLAN + WireGuard | Native Routing + WireGuard | Native Routing |
| --- | --- | --- | --- | --- |
| TCP Throughput (Gbit/s) | 7.6 | 2.1 | 2.4 | 12.0 |
| UDP Throughput (Gbit/s) | 1.5 | 0.8 | 1.0 | 2.0 |
| UDP Throughput Lost Datagrams (%) | 3.4 | 0.6 | 0.3 | 1.2 |
| Bidirectional Throughput (TX-C/RX-C) (Gbit/s) | 3.8/2.4 | 1.7/0.5 | 1.7/0.5 | 12.0/11.0 |
| TCP Latency (Mean µs/Transaction Rate) | 165/6057 | 237/4215 | 224/4449 | 124/ 8072 |
| UDP Latency (Mean µs/Transaction Rate) | 164/6077 | 237/4212 | 232/4300 | 122/ 8158 |
| TCP Stream (Throughput 10^6bits/sec) | 6927 | 2164 | 2225 | 11927 |

## Results Summary - Azure Kubernetes Service Comparison - Cilium 1.18.6

| Test | Azure CNI Overlay Native | Azure CNI Subnet Native | BYOCNI Native Routing | BYOCNI Native Routing 1.19.3 |
| --- | --- | --- | --- | --- |
| TCP Throughput (Gbit/s) | 6.4 | 7.1 | 8.8 | 12.0 |
| UDP Throughput (Gbit/s) | 1.3 | 1.3 | 2.0 | 2.0 |
| UDP Throughput Lost Datagrams (%) | 0.2 | 0.1 | 11.0 | 1.2 |
| Bidirectional Throughput (TX-C/RX-C) (Gbit/s) | 6.0/1.7 | 6.5/1.4 | 4.1/3.1 | 12.0/11.0 |
| TCP Latency (Mean µs/Transaction Rate) | 333/3000 | 123/8100 | 128/7826 | 124/8072 |
| UDP Latency (Mean µs/Transaction Rate) | 340/2944 | 125/3540 | 125/8006 | 122/8158 |
| TCP Stream (Throughput 10^6bits/sec) | 9809 | 8391 | 11497 | 11927 |

## Results Summary - ztunnel on BYOCNI on Azure Kubernetes Service - Cilium 1.19.3

| Test | Geneve | Geneve + ztunnel | Native Routing + ztunnel | Native Routing |
| --- | --- | --- | --- | --- |
| TCP Throughput (Gbit/s) | 7.2 | 9.6 | 12.0 | 12.0 |
| Bidirectional Throughput (TX-C/RX-C) (Gbit/s) | 4.0/2.4 | 4.4/3.8 | 10.5/9.1 | 12.0/11.0 |
| TCP Latency (Mean µs/Transaction Rate) | 164/6095 | 330/3030 | 261/3822 | 124/ 8072 |
| TCP Stream (Throughput 10^6bits/sec) | 6809 | 4608 | 6664 | 11927 |
