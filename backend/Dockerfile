FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

RUN node --env-file=.env.example scripts/init_db.js && \
    node --env-file=.env.example scripts/ingest_schemes.js

EXPOSE 4000
CMD ["node", "--env-file=.env.example", "src/server.js"]
