from fastapi import FastAPI

app = FastAPI(
    title="ML API",
    description="Sample ML API for the MLOps Helm Chart assignment",
    version="1.0.0",
)


@app.get("/")
def hello_world():
    return {
        "message": "Hello World",
        "service": "ml-api",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
    }
