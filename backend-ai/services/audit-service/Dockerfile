FROM python:3.10-slim

WORKDIR /workspace

# Install shared library
COPY shared /workspace/shared
RUN pip install --no-cache-dir -e /workspace/shared

# Install service-specific dependencies
COPY services/audit-service/requirements.txt /workspace/
RUN pip install --no-cache-dir -r requirements.txt

# Copy service code
COPY services/audit-service/app/ /workspace/app/

EXPOSE 4005

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4005"]
