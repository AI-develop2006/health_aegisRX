FROM python:3.10-slim

WORKDIR /workspace

COPY services/auth-service/requirements.txt /workspace/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Only this service's own code — NO shared monolith app/ copied
COPY services/auth-service/app/ /workspace/app/

EXPOSE 4001

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4001"]
