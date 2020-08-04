From python:stretch

COPY . /app
WORKDIR /app

RUN pip3 install pyjwt
RUN pip3 install flask
RUN pip3 install gunicorn
RUN pip3 install pytest

ENTRYPOINT ["gunicorn", "-b", ":8080", "main:APP"]