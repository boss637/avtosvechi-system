from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import products
from app.routers import compatibility

app = FastAPI(
    title="AVTOSVECHI / AUTOSHOP API",
    version="1.0.9-search-fixed",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/ready")
async def ready():
    return {"status": "ok"}


app.include_router(products.router)
app.include_router(compatibility.router)
