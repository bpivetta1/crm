# apps/app — Next.js. Upstream so publica para a Vercel; este arquivo existe
# para o self-host.
#
# Node E Bun: o bun e o gerenciador do monorepo, mas o postinstall de apps/api
# chama `node` e o engine do Prisma precisa de openssl.
FROM node:22-bookworm-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates openssl curl unzip \
 && rm -rf /var/lib/apt/lists/*
RUN npm install -g bun@1.3.12

WORKDIR /repo
COPY . .

# O bundle do cliente congela NEXT_PUBLIC_API_URL no momento do build
# (next.config.ts le API_URL), entao a origem real tem que estar aqui, nao so
# no runtime. O EasyPanel repassa a env do servico como --build-arg.
ARG API_URL=https://api-crm.nefo.pro
ARG APP_URL=https://crm.nefo.pro
ENV API_URL=${API_URL} \
    APP_URL=${APP_URL}

# Ver Dockerfile.api: prisma.config.ts exige DATABASE_URL ja no postinstall.
ARG DB_FACHADA=postgresql://build:build@127.0.0.1:5432/build?schema=public

# NODE_ENV so no fim: com production o bun pula as devDependencies e o turbo,
# que e quem faz o build, some.
RUN DATABASE_URL=$DB_FACHADA bun install --frozen-lockfile
RUN DATABASE_URL=$DB_FACHADA bunx turbo run build --filter=app

ENV NODE_ENV=production \
    PORT=3000
EXPOSE 3000
WORKDIR /repo/apps/app
CMD ["bun", "run", "start"]
