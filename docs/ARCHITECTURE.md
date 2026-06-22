# Flip Bills — System Architecture

## Overview

Flip Bills is a production-grade Flutter + Go fintech super-app for the Nigerian market.
It supports wallet management, VAS (airtime, data, electricity, TV/Cable, betting), travel booking, P2P/bank transfers, and a double-entry ledger accounting engine.

---

## High-Level Architecture

```mermaid
graph TB
    subgraph Client["Flutter Mobile App"]
        A[GoRouter] --> B[BLoC State Layer]
        B --> C[Repository Layer]
        C --> D[ApiClient - Dio + JWT]
    end

    subgraph Gateway["API Gateway - Nginx"]
        E[TLS Termination]
        F[Rate Limiting]
        G[Upstream Proxy]
    end

    subgraph Backend["Go Backend - Gin"]
        H[Auth Service]
        I[Wallet Service + Ledger]
        J[VAS / Utility Service]
        K[Travel Service]
        L[Transfer Service]
        M[Reconciliation Engine]
        N[Webhook Handler]
    end

    subgraph Providers["Payment Providers"]
        O[Paystack - Cards + Transfers]
        P[Flutterwave - Funding + Bills]
        Q[Monnify - Virtual Accounts]
        R[OPay - Bills Fallback]
    end

    subgraph Infrastructure["Infrastructure"]
        S[(PostgreSQL - Ledger + Users)]
        T[(Redis - Sessions + Cache)]
        U[(MongoDB - Travel Data)]
        V[RabbitMQ - Event Queue]
    end

    D --> E
    E --> H & I & J & K & L & N
    I --> S
    J --> O & P & Q & R
    L --> O
    N --> V
    V --> M
    M --> S
    I --> T
```

---

## Payment Flow — Wallet Funding

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant API as Go Backend
    participant FLW as Flutterwave
    participant DB as PostgreSQL Ledger

    App->>API: POST /api/v1/wallet/initialize-funding
    API->>FLW: Initialize payment (reference, amount, email)
    FLW-->>API: { authorization_url, reference }
    API-->>App: { payment_url, reference }
    App->>FLW: User completes payment in WebView

    Note over FLW,API: Webhook fires — NEVER trust frontend callback
    FLW->>API: POST /webhooks/flutterwave (signature in header)
    API->>API: Verify HMAC-SHA256 signature
    API->>DB: INSERT idempotency check (webhook_events)
    API->>DB: Credit ledger_entries (ON CONFLICT DO NOTHING)
    API-->>FLW: HTTP 200 OK
```

---

## Double-Entry Ledger Rules

| Rule | Implementation |
|---|---|
| **Balance computation** | `SELECT SUM(credit) - SUM(debit) FROM ledger_entries WHERE wallet_id = ?` |
| **No mutable balance column** | The `wallets` table has no `balance` field — balance is always computed |
| **Idempotency** | `UNIQUE(reference)` + `ON CONFLICT DO NOTHING` prevents double-credits |
| **Atomic debit** | Row-level `FOR UPDATE` lock prevents overdrafts in concurrent scenarios |
| **Audit trail** | Every kobo movement has a timestamped, immutable ledger entry |

---

## Provider Routing Strategy

```
Feature        Primary      Fallback 1    Fallback 2
──────────     ─────────    ──────────    ──────────
Card payments  Paystack     Flutterwave   Monnify
VAS bills      OPay         Flutterwave   Monnify
Bank transfers Paystack     Flutterwave   —
Virtual accts  Monnify      Paystack      —
```

Circuit breaker opens after **3 consecutive failures** and auto-resets after **60 seconds**.

---

## Database Schema Overview

```
users              — Registration, KYC, PIN
wallets            — One per user (no balance column)
ledger_entries     — Double-entry accounting (SUM gives balance)
transfers          — Outbound transfer lifecycle
virtual_accounts   — Monnify/Paystack dedicated virtual accounts
webhook_events     — Immutable audit log for all inbound webhooks
otp_codes          — SMS OTP lifecycle
travel_bookings    — Bus + flight bookings
loyalty_points     — Points earned per transaction
dispatcher_events  — Travel operator event log
```

---

## Deployment Architecture

```
Internet
    │
    ▼
Cloudflare (CDN + DDoS protection)
    │
    ▼
Nginx (TLS termination, rate limiting)
    │
    ▼
Railway / Fly.io (Go API, 3 instances)
    │
    ├── Railway PostgreSQL (production database)
    ├── Railway Redis (caching + sessions)
    ├── Railway MongoDB (travel partner data)
    └── CloudAMQP (managed RabbitMQ, free tier)
```

---

## Cost Optimization (Startup Phase)

| Service | Provider | Monthly Cost |
|---|---|---|
| API Hosting | Railway Starter | ~$5 |
| PostgreSQL | Railway | ~$5 |
| Redis | Railway | ~$3 |
| MongoDB | MongoDB Atlas Free | $0 |
| RabbitMQ | CloudAMQP Little Lemur | $0 |
| CDN | Cloudflare Free | $0 |
| SMS (OTP) | Termii | Pay-as-you-go |
| Payments | Paystack / Flutterwave | 1.5% per txn |
| **Total infra** | | **~$13/month** |

Scale to Kubernetes (GKE Autopilot) when monthly active users exceed 50,000.

---

## Security Checklist

- [x] JWT access tokens (15min TTL) + refresh tokens (30 days)
- [x] Refresh token rotation on every use
- [x] Webhook HMAC signature verification (Paystack SHA-512, Flutterwave SHA-256)
- [x] Idempotency keys on all payment operations
- [x] Redis rate limiting (100 req/min per IP)
- [x] Biometric confirmation before transfers
- [x] OTP verification on registration + sensitive actions
- [ ] BVN/NIN verification (add when reaching 10k users)
- [ ] 2FA via TOTP (Phase 3)
- [ ] Transaction limits enforcement (Phase 3)
