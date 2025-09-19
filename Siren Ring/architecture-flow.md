# SIREN Ring System Architecture

## System Flow Diagram

```mermaid
flowchart LR
    A[SIREN Ring Device] --> B[Your Swift App]
    B --> C[Go HTTP Server]
    C --> D[CockroachDB]
    C --> E[Apple Push Service]
    E --> F[Contact's Swift App]
    
    G[Contact's Swift App] --> C
```