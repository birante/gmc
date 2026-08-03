# From Frame to Forward — Building a Functional Local Network

Networking checkpoint: design a small company-floor LAN, assign L2/L3 addresses, explain how a frame travels from a PC to the printer, describe collision handling on both Ethernet and Wi-Fi, and trace an outbound packet from a wireless client to the public Internet (including NAT).

Read the full analysis in [`analysis.md`](./analysis.md). Diagrams render directly on GitHub via Mermaid.

## Table of contents

| Part | Topic                        | Key result                                                    |
| ---- | ---------------------------- | ------------------------------------------------------------- |
| 0    | Topology                     | 1 router (WAN + 2 LAN legs) → 2 switches → 4 PCs + 1 printer; AP with 2 wireless clients on a separate subnet. |
| 1    | MAC & Frame Handling         | Locally-administered MACs; Ethernet II frame anatomy; CSMA/CD (wired) vs CSMA/CA (Wi-Fi). |
| 2    | IP Addressing & Subnetting   | Two /24 subnets: `192.168.10.0/24` (wired) and `192.168.20.0/24` (wireless); DHCP handled by the router. |
| 3    | Routing, Forwarding, NAT     | Wireless client → public host, showing IP header inspection, next-hop lookup, and PAT rewrite on egress/return. |
