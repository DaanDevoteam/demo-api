from fastapi import FastAPI, HTTPException, Request
import logging

# --- LOGGING SETUP ---
logging.basicConfig(
    filename="api.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

app = FastAPI()

@app.middleware("http")
async def log_requests(request: Request, call_next):
    logging.info(f"Incoming request: {request.method} {request.url}")
    response = await call_next(request)
    logging.info(f"Response status: {response.status_code}")
    return response

@app.get("/ping")
async def ping():
    return {"message": "pong"}

@app.get("/process")
async def process(code: str):
    valid_code = "SECRET123"

    if code != valid_code:
        logging.error(f"Invalid code attempted: {code}")
        raise HTTPException(status_code=400, detail="Invalid code parameter")

    logging.info("Code validated successfully")
    return {"status": "success", "detail": "Processed successfully"}

# --- STRICT PARAMETER ENDPOINT 2 ---
@app.get("/validate")
async def validate(token: str):
    expected = "TOKEN-999"

    if token != expected:
        logging.error(f"Invalid token attempted: {token}")
        raise HTTPException(status_code=401, detail="Invalid token")

    logging.info("Token validated successfully")
    return {"status": "success", "detail": "Token validated"}


# --- STRICT PARAMETER ENDPOINT 3 ---
@app.get("/compute")
async def compute(secret: str):
    expected = "COMPUTE-777"

    if secret != expected:
        logging.error(f"Invalid compute secret attempted: {secret}")
        raise HTTPException(status_code=403, detail="Invalid compute secret")

    logging.info("Compute secret validated successfully")
    return {"status": "success", "detail": "Computation executed"}


# --- STRICT PARAMETER ENDPOINT 4 ---
@app.get("/authorize")
async def authorize(key: str):
    expected = "AUTH-555"

    if key != expected:
        logging.error(f"Invalid authorization key attempted: {key}")
        raise HTTPException(status_code=401, detail="Authorization failed")

    logging.info("Authorization key validated successfully")
    return {"status": "success", "detail": "Access authorized"}


# --- STRICT PARAMETER ENDPOINT 5 ---
@app.get("/simulate")
async def simulate(flag: str):
    expected = "SIM-TEST"

    if flag != expected:
        logging.error(f"Simulation failed for flag: {flag}")
        raise HTTPException(status_code=400, detail="Simulation flag invalid")

    logging.info("Simulation flag validated successfully")
    return {"status": "success", "detail": "Simulation executed"}