from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from database import connect_db, close_db
from routes.auth_routes import router as auth_router
from routes.sos_routes import router as sos_router
from routes.complaint_routes import router as complaint_router
from routes.dashboard_routes import router as dashboard_router
from routes.admin_routes import router as admin_router
from routes.upload_routes import router as upload_router
from routes.cctv_routes import router as cctv_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()


app = FastAPI(
    title="College SOS API",
    description="Backend for College SOS — Student Safety & Support Platform",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(sos_router)
app.include_router(complaint_router)
app.include_router(dashboard_router)
app.include_router(admin_router)
app.include_router(upload_router)
app.include_router(cctv_router)


@app.get("/")
async def root():
    return {
        "message": "College SOS API v2.0 🚀",
        "storage": "Cloudinary CDN",
        "docs": "/docs",
    }


@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.0.0"}
