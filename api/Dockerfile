FROM node:10

RUN mkdir /app

WORKDIR /app

ADD package*.json ./

RUN npm install

COPY . /app
