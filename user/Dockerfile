# 1. pick a Node 22 image
FROM node:22-alpine

# 2. set a working directory
WORKDIR /app

# 3. declare all the environment variables needed
ENV PORT=3000 \
    DATABASE_HOST=postgres \
    DATABASE_PORT=5432 \
    DATABASE_NAME=postgres \
    DATABASE_USERNAME=postgres \
    DATABASE_PASSWORD=foo

# 4. copy the app into the work directory
COPY package*.json ./

# 5. install all the packages needed for NodeJS
RUN npm ci --omit=dev
COPY . .

# 6. expose the port needed
EXPOSE 3000

# 7. start the app
CMD ["npm", "start"]    
