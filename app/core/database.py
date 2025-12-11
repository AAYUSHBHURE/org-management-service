from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

class Database:
    client: AsyncIOMotorClient = None

db = Database()

async def get_db_client() -> AsyncIOMotorClient:
    return db.client

async def get_master_db():
    return db.client[settings.MASTER_DB_NAME]

async def get_org_db(org_collection_name: str):
    # In this design, we use the same database but different collections.
    # Alternatively, we could use different databases per org.
    # The requirement says "create dynamic collections", implying same DB, different collections.
    # However, to be strictly "multi-tenant", sometimes separate DBs are better.
    # But sticking to "Example collection name pattern: org_<organization_name>" implies single DB.
    # Let's clarify: The requirements say "create dynamic collections... specific for the organization".
    # And "Store... Organization collection name".
    # So we will use the same MASTER_DB_NAME for ease, OR a dedicated "Tenants" DB.
    # Let's use a dedicated DB for tenants or just put them in the same DB as master?
    # Master DB usually holds metadata. It's cleaner to keep tenant collections separate or in a dedicated "tenants_db".
    # BUT, the pattern 'org_<name>' suggests they might live alongside others.
    # Let's assume they live in the same DB or a specific 'organizations' DB.
    # For this implementation, I will put them in a separate database called 'organizations_db' to keep 'master_db' clean.
    # Wait, requirements: "Master Database for global metadata and create dynamic collections for each organization."
    # It doesn't explicitly say separate DB. But "org_<name>" is a collection name.
    # So I will return a collection object.
    
    # We will use a separate database for tenant data to keep it clean, 
    # or just use the same DB if simpler. Let's use 'tenants_db'.
    return db.client["tenants_db"][org_collection_name]

async def connect_to_mongo():
    db.client = AsyncIOMotorClient(settings.MONGODB_URL)
    print("Connected to MongoDB")

async def close_mongo_connection():
    db.client.close()
    print("Closed MongoDB connection")
