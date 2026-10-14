
FROM node:22-alpine

WORKDIR /app

ENV PORT=3000 \

    DATABASE_HOST=postgres \

    DATABASE_PORT=5432 \

    DATABASE_NAME=postgres \

    DATABASE_USERNAME=postgres \

    DATABASE_PASSWORD=foo

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .

EXPOSE 3000

CMD ["npm", "start"]    

