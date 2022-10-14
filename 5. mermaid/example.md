```mermaid
flowchart LR
    Internet -- Authentication --> aad(Azure Active Directory)
    
    Internet --> cdn(Azure CDN) & frontDoor(Azure Front Door)
    Internet --> dns(Azure DNS)

    
   
    subgraph Resource Group
        blob(Blob Storage) --> cdn
        frontDoor ---> webApp(Web App)
        redis(Redis Cache) --> webApp
        sql(Azure SQL Database) --> redis
    end
```