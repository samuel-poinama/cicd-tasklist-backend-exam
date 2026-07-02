FROM node:24-alpine AS intaller

WORKDIR /app
COPY package.json package-lock.json ./

RUN npm install


FROM node:24-alpine AS builder

WORKDIR /app
COPY --from=intaller /app/node_modules ./node_modules
COPY . .

RUN npm run build

FROM node:24-alpine AS runner

WORKDIR /app
COPY --from=intaller /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist

CMD ["node", "dist/server.js"]