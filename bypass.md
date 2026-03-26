# Preventing DNS Bypass

The core limitation of this setup: since the server isn't in the routing path, packets to `8.8.8.8` go straight through the Xfinity router without touching your Pi-hole. A tech-savvy kid can bypass bedtime restrictions by hardcoding a different DNS server.

Here's the threat model by skill level and how to counter each.

---

## Easy wins (stops most kids)

### Block outbound port 53 at the Xfinity router

Log into http://10.0.0.1 → Advanced → Security/Firewall. If it supports outbound port filtering, block UDP/TCP port 53 to any IP *except* `10.0.0.249`. Devices with hardcoded DNS like `8.8.8.8` will get no response.

This stops: changing DNS settings in OS/app, most apps with hardcoded DNS.

---

## Trickier: DNS over HTTPS (DoH)

The next move is enabling DoH in a browser or OS — this tunnels DNS over port 443 (HTTPS), bypassing port 53 blocks entirely.

**Counter**: Pi-hole can block the DoH provider domains so the device can't even resolve them:

```
dns.google
dns.cloudflare.com
mozilla.cloudflare-dns.com
doh.opendns.com
dns.quad9.net
```

Add these as exact blocks in Pi-hole → Domains. The device tries to resolve the DoH provider, Pi-hole blocks that lookup, DoH fails and falls back to standard DNS — which is blocked at bedtime.

---

## Nuclear option: transparent DNS proxy

Put the server **in the routing path** so `iptables` can intercept *all* port 53 traffic and redirect it to Pi-hole regardless of destination. This is what the [original blog post's OpenBSD setup](https://ratfactor.com/openbsd/pf-gateway-bedtime) does fully.

**Requires**: a second NIC in the server (a USB-to-ethernet adapter is ~$15) and configuring it as the actual network gateway instead of relying on the Xfinity router for routing. Significant setup but airtight against port 53 bypass.

---

## The VPN problem

A determined kid can install a VPN (Mullvad, Proton, etc.) and tunnel everything — all traffic leaves encrypted on port 443 and DNS rules are irrelevant. Stopping this requires:

- **Allowlisting** only known-good IPs at the router (very high maintenance)
- **Deep packet inspection** (not realistic on consumer hardware)
- **Non-technical controls**: parental trust conversation, device-level parental controls (Screen Time on iOS, Family Link on Android), or physical device collection at bedtime

---

## Practical recommendation

Start with **blocking port 53 at the Xfinity router** + **Pi-hole DoH domain blocks**. That covers 95% of bypass attempts without new hardware. If they escalate to VPNs, that's a Screen Time/Family Link problem, not a DNS problem.
