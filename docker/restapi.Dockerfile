FROM python:3.11

WORKDIR /app

COPY RESTApi/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY RESTApi/ /app/

ENV FLASK_APP=MyRamesServer.py
ENV FLASK_ENV=production

CMD ["sh", "start-server.sh"]
