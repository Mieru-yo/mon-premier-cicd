# Dockerfile - Application Calculator API

# STAGE 1: BUILD & TEST
FROM node:18-alpine AS builder

WORKDIR /app

# Copy dependency files first for better layer caching
COPY package*.json ./

# Install all deps (dev + prod) for tests
RUN npm ci

# Copy source
COPY . .

# Fail image build if tests fail
RUN npm test

# STAGE 2: RUNTIME
FROM node:18-alpine AS runtime

WORKDIR /app

# Copy only runtime assets from builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/src ./src

# Install prod-only deps
RUN npm ci --only=production

# Run as non-root user
USER node

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "src/server.js"]
