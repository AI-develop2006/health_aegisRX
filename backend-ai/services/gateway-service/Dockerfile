FROM python:3.10-slim

WORKDIR /workspace

# Install shared library if needed (shown as pattern)
COPY shared /workspace/shared
RUN pip install --no-cache-dir -e /workspace/shared

# Install service dependencies
COPY services/gateway-service/requirements.txt /workspace/
RUN pip install --no-cache-dir -r requirements.txt

# Copy service code
COPY services/gateway-service/app/ /workspace/app/

EXPOSE 4000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4000"]
