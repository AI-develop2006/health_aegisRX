FROM python:3.10-slim

WORKDIR /workspace

COPY services/pharmacy-service/requirements.txt /workspace/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY services/pharmacy-service/app/ /workspace/app/

EXPOSE 4006

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4006"]
