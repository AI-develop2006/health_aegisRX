FROM python:3.10-slim

WORKDIR /workspace

COPY services/patient-service/requirements.txt /workspace/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY services/patient-service/app/ /workspace/app/

EXPOSE 4002

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4002"]
