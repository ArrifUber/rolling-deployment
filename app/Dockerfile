FROM python:3.10-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir -r requirements.txt
RUN apt-get update && apt-get install curl -y 
EXPOSE 5000
CMD ["gunicorn", "app:app", "-b", "0.0.0.0:5000"]
