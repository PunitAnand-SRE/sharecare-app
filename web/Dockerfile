
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN NODE_OPTIONS=--openssl-legacy-provider npm run build

EXPOSE 5000

ENV NUXT_HOST=0.0.0.0

ENV NUXT_PORT=5000

ENV BASE_URL=http://localhost:3000

CMD ["npm", "start"]

