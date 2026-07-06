FROM python:3.10-slim

WORKDIR /workspace

COPY services/audit-service/requirements.txt /workspace/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY services/audit-service/app/ /workspace/app/

EXPOSE 4005

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4005"]
