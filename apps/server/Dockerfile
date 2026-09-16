ARG NODE_IMAGE=node:24.21.0-trixie-slim

FROM ${NODE_IMAGE} AS base

ENV PNPM_HOME=/pnpm
ENV PATH=${PNPM_HOME}:${PATH}

WORKDIR /app

RUN corepack enable \
    && corepack install --global pnpm@10.2.1 \
    && mkdir -p "${PNPM_HOME}" \
    && chown -R node:node /app "${PNPM_HOME}"

FROM base AS deps

USER node

COPY --chown=node:node package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY --chown=node:node prisma ./prisma
RUN pnpm install --frozen-lockfile \
    && pnpm prisma:generate

FROM deps AS development

COPY --chown=node:node nest-cli.json tsconfig.json tsconfig.build.json ./
COPY --chown=node:node prisma ./prisma
COPY --chown=node:node src ./src

ENV NODE_ENV=development
ENV APP_HOST=0.0.0.0
ENV PORT=8080

EXPOSE 8080

CMD ["sh", "-c", "pnpm prisma db push && pnpm prisma db seed && pnpm start:dev"]

FROM deps AS build

COPY --chown=node:node nest-cli.json tsconfig.json tsconfig.build.json ./
COPY --chown=node:node prisma ./prisma
COPY --chown=node:node src ./src

RUN pnpm build

FROM deps AS test

COPY --chown=node:node nest-cli.json tsconfig.json tsconfig.build.json ./
COPY --chown=node:node .prettierrc eslint.config.mjs ./
COPY --chown=node:node prisma ./prisma
COPY --chown=node:node src ./src

RUN pnpm test \
    && pnpm lint \
    && pnpm format:check

FROM base AS prod-deps

USER node

COPY --chown=node:node package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY --chown=node:node prisma ./prisma
RUN pnpm install --prod --frozen-lockfile \
    && pnpm prisma:generate

FROM ${NODE_IMAGE} AS runtime

ENV NODE_ENV=production
ENV APP_HOST=0.0.0.0
ENV PORT=8080

WORKDIR /app

COPY --chown=node:node package.json ./
COPY --chown=node:node prisma ./prisma
COPY --chown=node:node --from=prod-deps /app/node_modules ./node_modules
COPY --chown=node:node --from=build /app/dist ./dist

USER node

EXPOSE 8080

CMD ["node", "dist/main.js"]
