FROM python:3.10-slim

WORKDIR /workspace

# Install shared library
COPY shared /workspace/shared
RUN pip install --no-cache-dir -e /workspace/shared

# Install service-specific dependencies
COPY services/prescription-service/requirements.txt /workspace/
RUN pip install --no-cache-dir -r requirements.txt

# Copy service code
COPY services/prescription-service/app/ /workspace/app/

EXPOSE 4004

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4004"]
