from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.routers import organization, admin
from app.core.database import connect_to_mongo, close_mongo_connection
from app.core.config import settings

@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_to_mongo()
    yield
    await close_mongo_connection()

app = FastAPI(
    title=settings.PROJECT_NAME,
    lifespan=lifespan
)

app.include_router(organization.router)
app.include_router(admin.router)

@app.get("/")
async def root():
    return {"message": "Organization Management Service is running"}
