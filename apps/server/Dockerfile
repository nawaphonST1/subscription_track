ARG NODE_IMAGE=node:22-alpine3.20

FROM ${NODE_IMAGE} AS base

ENV PNPM_HOME=/pnpm
ENV PNPM_STORE_DIR=/pnpm/store
ENV PATH=${PNPM_HOME}:${PATH}

WORKDIR /app

RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache libc6-compat openssl \
    && corepack enable \
    && corepack install --global pnpm@10.2.1 \
    && mkdir -p "${PNPM_HOME}" /pnpm/store \
    && chown -R node:node /app "${PNPM_HOME}" /pnpm/store

FROM base AS build

USER node

COPY --chown=node:node package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY --chown=node:node prisma ./prisma
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store,uid=1000,gid=1000 \
    pnpm install --frozen-lockfile \
    && pnpm prisma:generate

COPY --chown=node:node nest-cli.json tsconfig.json tsconfig.build.json ./
COPY --chown=node:node src ./src

RUN pnpm build \
    && pnpm prune --prod \
    && rm -rf /app/node_modules/.pnpm/deepmerge-ts* /app/node_modules/deepmerge-ts

FROM ${NODE_IMAGE} AS runtime

RUN apk update && apk upgrade --no-cache \
    && apk add --no-cache libc6-compat openssl \
    && rm -rf /usr/local/lib/node_modules/npm \
              /usr/local/bin/npm \
              /usr/local/bin/npx \
              /usr/local/bin/corepack \
              /root/.npm \
              /root/.cache

ENV NODE_ENV=production
ENV APP_HOST=0.0.0.0
ENV PORT=8080

WORKDIR /app

COPY --chown=node:node package.json ./
COPY --chown=node:node prisma ./prisma
COPY --chown=node:node --from=build /app/node_modules ./node_modules
COPY --chown=node:node --from=build /app/dist ./dist

USER node

EXPOSE 8080

CMD ["node", "dist/main.js"]
