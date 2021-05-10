FROM swift:latest

RUN apt-get -q update && apt-get -q upgrade -y
RUN apt-get install -y firebird-dev

WORKDIR /app

COPY . .

RUN swift package resolve