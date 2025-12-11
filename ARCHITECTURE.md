# Architecture Diagram

```mermaid
graph TB
    Client[API Clients]
    
    subgraph FastAPI["FastAPI Application"]
        OrgRouter["/org Router<br/>Create, Get, Update, Delete"]
        AdminRouter["/admin Router<br/>Login"]
        
        Security["Security Module<br/>• PBKDF2 Password Hashing<br/>• JWT Token Generation"]
        Database["Database Module<br/>Motor Async Driver"]
    end
    
    subgraph MongoDB["MongoDB"]
        MasterDB["Master Database<br/>• Organization Metadata<br/>• Admin Credentials"]
        OrgCollections["Dynamic Collections<br/>• org_TechCorp<br/>• org_Acme<br/>• org_..."]
    end
    
    Client -->|HTTP Requests| OrgRouter
    Client -->|HTTP Requests| AdminRouter
    
    OrgRouter --> Security
    OrgRouter --> Database
    AdminRouter --> Security
    AdminRouter --> Database
    
    Database --> MasterDB
    Database --> OrgCollections
    
    style Client fill:#e1f5ff
    style FastAPI fill:#fff4e1
    style MongoDB fill:#e8f5e9
    style Security fill:#fce4ec
    style Database fill:#fce4ec
```

## Component Descriptions

### Client Layer
- External applications and API consumers making HTTP requests

### API Layer
- **Organization Router**: CRUD operations for organizations
- **Admin Router**: Authentication endpoint returning JWT tokens

### Business Logic Layer
- **Security Module**: Handles password hashing (PBKDF2-SHA256) and JWT generation
- **Database Module**: Async MongoDB operations using Motor driver

### Data Layer
- **Master Database**: Stores organization metadata and admin credentials
- **Dynamic Collections**: One collection per organization for complete data isolation
