ARG PARENT_IMAGE
FROM ${PARENT_IMAGE} AS base
WORKDIR /app
EXPOSE 3000

FROM base AS debug
# Dev target expects source to be bind-mounted at /app and a named volume
# masking /app/node_modules (see docker-compose.yml).
# First boot populates the empty node_modules volume; subsequent boots see
# it already populated and skip install for fast startup.
CMD ["sh", "-c", "if [ -z \"$(ls -A node_modules 2>/dev/null)\" ]; then echo '>> node_modules empty, running npm install...'; npm install; fi && npm run dev"]

FROM base AS production
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
CMD ["npm", "run", "start"]
