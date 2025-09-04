# SIREN Ring System Architecture Flow

## Current 6-Digit Code Flow

```mermaid
sequenceDiagram
    participant A as Contact's iPhone
    participant B as Your iPhone  
    participant C as Go Server
    participant D as CockroachDB
    participant E as APNs

    Note over A,E: 1. Contact Registration Flow
    A->>A: Generate 6-digit code (123456)
    A->>C: POST /api/auth-code {code, device_token, device_name}
    C->>D: INSERT auth_codes (code, device_token) TTL 10min
    D-->>C: Success
    C-->>A: Code created

    Note over A,E: 2. Adding Emergency Contact
    B->>B: User enters code 123456
    B->>C: GET /api/auth-code/123456
    C->>D: SELECT device_token FROM auth_codes WHERE code='123456'
    D-->>C: Return device_token + device_name
    C-->>B: Contact info
    B->>B: Save contact locally

    Note over A,E: 3. Emergency Alert Flow
    B->>B: SIREN Ring activated
    B->>C: POST /api/emergency {user_id, device_tokens[], message}
    C->>D: INSERT emergency_alerts (log the event)
    C->>E: Send push notifications to all device_tokens
    E-->>A: Push notification received
    C-->>B: Success response
    B->>B: Show "Alert sent to X contacts"
```

## Alternative Connection Methods (All Need Database)

### QR Code Flow
```mermaid
sequenceDiagram
    participant A as Contact's iPhone
    participant B as Your iPhone  
    participant C as Go Server
    participant D as CockroachDB

    A->>A: Generate QR code with device_token
    A->>C: POST /api/qr-register {device_token, device_name}
    C->>D: INSERT qr_codes (qr_id, device_token) TTL 5min
    B->>B: Scan QR code → get qr_id
    B->>C: GET /api/qr-lookup/qr_id
    C->>D: SELECT device_token WHERE qr_id=?
    D-->>B: Return contact info
```

### User Account System
```mermaid
sequenceDiagram
    participant A as Contact's iPhone
    participant B as Your iPhone  
    participant C as Go Server
    participant D as CockroachDB

    A->>C: POST /api/register {email, device_token}
    C->>D: INSERT users (email, device_token)
    B->>C: POST /api/add-contact {contact_email}
    C->>D: SELECT device_token WHERE email=?
    D-->>B: Return device_token
```

### Direct Token Sharing (No intermediary)
```mermaid
sequenceDiagram
    participant A as Contact's iPhone
    participant B as Your iPhone  
    participant C as Go Server
    participant D as CockroachDB

    A->>A: Copy device token from settings
    A->>B: Send token via text/email
    B->>B: Paste token directly
    Note over A,B: Still need database for emergency alerts
    B->>C: POST /api/emergency {device_tokens[]}
    C->>D: Log emergency event
```

## System Components

```mermaid
graph TB
    subgraph "iOS Apps"
        A[Your SIREN Ring App]
        B[Contact's SIREN Ring App]
    end
    
    subgraph "Backend Services"
        C[Go HTTP Server]
        D[CockroachDB]
        E[Apple Push Notification Service]
    end
    
    subgraph "Hardware"
        F[SIREN Ring Device]
    end
    
    F -->|Bluetooth| A
    A -->|HTTP API| C
    B -->|HTTP API| C
    C -->|SQL| D
    C -->|Push Notifications| E
    E -->|APNs| B
    
    style F fill:#ff9999
    style E fill:#99ccff
    style D fill:#99ff99
```