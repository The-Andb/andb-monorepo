FROM node:18.20.4 as base
RUN npm install -g npm@10.1.0
WORKDIR /app
COPY . .
RUN npm ci