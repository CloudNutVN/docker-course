FROM python:2.7.14

WORKDIR /usr/src/app

COPY ./requirements.txt requirements.txt

RUN pip install -r requirements.txt

ENTRYPOINT ["python", "app.py"]

COPY ./app.py app.py