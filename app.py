import os
import logging
import time
import uuid
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

# --- AZURE MONITOR / APPLICATION INSIGHTS SETUP ---
# Only configure if connection string is available (in Azure)
connection_string = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")

if connection_string:
    from azure.monitor.opentelemetry import configure_azure_monitor
    configure_azure_monitor(
        connection_string=connection_string,
        enable_live_metrics=True,
    )

# --- LOGGING SETUP ---
# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Demo API", version="1.0.0")


# --- HELPER: Structured log with custom dimensions ---
def log_structured(
    level: str,
    message: str,
    request_id: str = None,
    endpoint: str = None,
    method: str = None,
    status_code: int = None,
    duration_ms: float = None,
    client_ip: str = None,
    error_type: str = None,
    parameters: dict = None,
    **extra
):
    """
    Log a structured message with custom dimensions for Application Insights.
    These custom dimensions are queryable via KQL in Azure.
    """
    custom_dimensions = {
        "request_id": request_id,
        "endpoint": endpoint,
        "method": method,
        "status_code": status_code,
        "duration_ms": duration_ms,
        "client_ip": client_ip,
        "error_type": error_type,
        "parameters": str(parameters) if parameters else None,
        **extra
    }
    # Remove None values
    custom_dimensions = {k: v for k, v in custom_dimensions.items() if v is not None}
    
    log_func = getattr(logger, level.lower(), logger.info)
    log_func(message, extra={"custom_dimensions": custom_dimensions})


# --- MIDDLEWARE: Request tracking with structured logging ---
@app.middleware("http")
async def log_requests(request: Request, call_next):
    # Generate unique request ID
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id
    
    # Capture request details
    start_time = time.time()
    endpoint = request.url.path
    method = request.method
    client_ip = request.client.host if request.client else "unknown"
    
    # Get query parameters (for logging)
    params = dict(request.query_params)
    
    # Log incoming request
    log_structured(
        level="INFO",
        message=f"Request started: {method} {endpoint}",
        request_id=request_id,
        endpoint=endpoint,
        method=method,
        client_ip=client_ip,
        parameters=params
    )
    
    # Process request
    try:
        response = await call_next(request)
        duration_ms = (time.time() - start_time) * 1000
        
        # Log completed request
        log_structured(
            level="INFO" if response.status_code < 400 else "WARNING",
            message=f"Request completed: {method} {endpoint}",
            request_id=request_id,
            endpoint=endpoint,
            method=method,
            status_code=response.status_code,
            duration_ms=round(duration_ms, 2),
            client_ip=client_ip,
            parameters=params
        )
        
        # Add request ID to response headers for tracing
        response.headers["X-Request-ID"] = request_id
        return response
        
    except Exception as e:
        duration_ms = (time.time() - start_time) * 1000
        
        # Log error
        log_structured(
            level="ERROR",
            message=f"Request failed: {method} {endpoint} - {str(e)}",
            request_id=request_id,
            endpoint=endpoint,
            method=method,
            status_code=500,
            duration_ms=round(duration_ms, 2),
            client_ip=client_ip,
            error_type=type(e).__name__,
            error_message=str(e),
            parameters=params
        )
        raise


# --- EXCEPTION HANDLER: Structured error logging ---
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    request_id = getattr(request.state, 'request_id', 'unknown')
    endpoint = request.url.path
    method = request.method
    params = dict(request.query_params)
    client_ip = request.client.host if request.client else "unknown"
    
    log_structured(
        level="ERROR",
        message=f"HTTP Exception: {exc.detail}",
        request_id=request_id,
        endpoint=endpoint,
        method=method,
        status_code=exc.status_code,
        client_ip=client_ip,
        error_type="HTTPException",
        error_message=exc.detail,
        parameters=params
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "detail": exc.detail,
            "request_id": request_id
        },
        headers={"X-Request-ID": request_id}
    )


# --- HEALTH CHECK ENDPOINT ---
@app.get("/health")
async def health():
    """Health check endpoint for Azure App Service."""
    return {"status": "healthy"}


@app.get("/ping")
async def ping():
    return {"message": "pong"}


# --- ENDPOINT: /process ---
@app.get("/process")
async def process(request: Request, code: str):
    valid_code = "SECRET123"
    request_id = getattr(request.state, 'request_id', 'unknown')

    if code != valid_code:
        log_structured(
            level="ERROR",
            message="Invalid code attempted",
            request_id=request_id,
            endpoint="/process",
            error_type="InvalidCodeError",
            parameters={"code": code}
        )
        raise HTTPException(status_code=400, detail="Invalid code parameter")

    log_structured(
        level="INFO",
        message="Code validated successfully",
        request_id=request_id,
        endpoint="/process"
    )
    return {"status": "success", "detail": "Processed successfully", "request_id": request_id}


# --- ENDPOINT: /validate ---
@app.get("/validate")
async def validate(request: Request, token: str):
    expected = "TOKEN-999"
    request_id = getattr(request.state, 'request_id', 'unknown')

    if token != expected:
        log_structured(
            level="ERROR",
            message="Invalid token attempted",
            request_id=request_id,
            endpoint="/validate",
            error_type="InvalidTokenError",
            parameters={"token": token}
        )
        raise HTTPException(status_code=401, detail="Invalid token")

    log_structured(
        level="INFO",
        message="Token validated successfully",
        request_id=request_id,
        endpoint="/validate"
    )
    return {"status": "success", "detail": "Token validated", "request_id": request_id}


# --- ENDPOINT: /compute ---
@app.get("/compute")
async def compute(request: Request, secret: str):
    expected = "COMPUTE-777"
    request_id = getattr(request.state, 'request_id', 'unknown')

    if secret != expected:
        log_structured(
            level="ERROR",
            message="Invalid compute secret attempted",
            request_id=request_id,
            endpoint="/compute",
            error_type="InvalidSecretError",
            parameters={"secret": secret}
        )
        raise HTTPException(status_code=403, detail="Invalid compute secret")

    log_structured(
        level="INFO",
        message="Compute secret validated successfully",
        request_id=request_id,
        endpoint="/compute"
    )
    return {"status": "success", "detail": "Computation executed", "request_id": request_id}


# --- ENDPOINT: /authorize ---
@app.get("/authorize")
async def authorize(request: Request, key: str):
    expected = "AUTH-555"
    request_id = getattr(request.state, 'request_id', 'unknown')

    if key != expected:
        log_structured(
            level="ERROR",
            message="Invalid authorization key attempted",
            request_id=request_id,
            endpoint="/authorize",
            error_type="AuthorizationError",
            parameters={"key": key}
        )
        raise HTTPException(status_code=401, detail="Authorization failed")

    log_structured(
        level="INFO",
        message="Authorization key validated successfully",
        request_id=request_id,
        endpoint="/authorize"
    )
    return {"status": "success", "detail": "Access authorized", "request_id": request_id}


# --- ENDPOINT: /simulate ---
@app.get("/simulate")
async def simulate(request: Request, flag: str):
    expected = "SIM-TEST"
    request_id = getattr(request.state, 'request_id', 'unknown')

    if flag != expected:
        log_structured(
            level="ERROR",
            message="Simulation failed for flag",
            request_id=request_id,
            endpoint="/simulate",
            error_type="SimulationError",
            parameters={"flag": flag}
        )
        raise HTTPException(status_code=400, detail="Simulation flag invalid")

    log_structured(
        level="INFO",
        message="Simulation flag validated successfully",
        request_id=request_id,
        endpoint="/simulate"
    )
    return {"status": "success", "detail": "Simulation executed", "request_id": request_id}
