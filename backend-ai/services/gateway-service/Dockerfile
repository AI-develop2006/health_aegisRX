FROM python:3.10-slim

WORKDIR /workspace

COPY services/gateway-service/requirements.txt /workspace/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY services/gateway-service/app/main.py /workspace/app/main.py
RUN touch /workspace/app/__init__.py

EXPOSE 4000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "4000"]
