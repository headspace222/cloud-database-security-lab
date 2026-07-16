# Architecture Diagram

```mermaid
flowchart TB
    subgraph Auth["Authentication - Entra Only"]
        direction TB
        A1[SQL Login Attempt] -->|Rejected| A2[SQL Authentication Disabled]
        A3[Entra ID Login Attempt] -->|Accepted| A4[Microsoft Entra Admin]
    end

    subgraph Network["Network Access"]
        direction TB
        N1[Connection from Known IP] -->|Allowed| N2[Firewall Rule AllowMyClientIP]
        N3[Connection from Any Other IP] -->|Denied| N2
    end

    subgraph DB["Azure SQL Database Free Offer"]
        direction TB
        D1[db-security-baseline]
        D2[Transparent Data Encryption default]
    end

    subgraph Audit["Shared Observability"]
        direction TB
        L1[Log Analytics Workspace from Observability Capstone]
    end

    A4 --> D1
    N2 --> D1
    D1 -->|every login and query| L1

    style Auth fill:#e8f4fd,stroke:#1a73e8
    style Network fill:#fce8e6,stroke:#d93025
    style DB fill:#e6f4ea,stroke:#188038
    style Audit fill:#fef7e0,stroke:#f9ab00
```

## Reading This Diagram

Authentication (top, blue): SQL logins are rejected unconditionally. Only Entra ID identities can reach the database.

Network (middle, red): a firewall rule permitting exactly one known IP, denying everything else by default.

Database (bottom-left, green): the free-offer serverless database itself, with Transparent Data Encryption active by default.

Audit (bottom-right, amber): every login attempt and query flows into the same shared Log Analytics workspace the observability capstone built.