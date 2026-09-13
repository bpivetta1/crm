#!/bin/sh
# Garante que o banco do CRM existe.
#
# Por que banco proprio e nao um schema: as migracoes do upstream tem "public"
# escrito na mao (ex.: ALTER TABLE "public"."mailboxSync" na
# 20260731210000_forward_only_sync). Com ?schema=crm a migracao encontra a
# tabela em crm mas tenta alterar em public, falha, e o Prisma trava tudo
# depois com P3009. Banco separado, schema public dele, resolve — e ainda
# isola do que ja usa o bd_bruno.
cd /repo || exit 1
exec bun -e '
const { Client } = require("pg");
const alvo = new URL(process.env.DATABASE_URL);
const nome = decodeURIComponent(alvo.pathname.slice(1));
const admin = new URL(process.env.DATABASE_URL);
admin.pathname = "/postgres";
admin.search = "";
const c = new Client({ connectionString: admin.toString() });
(async () => {
  await c.connect();
  const r = await c.query("SELECT 1 FROM pg_database WHERE datname=$1", [nome]);
  if (r.rowCount === 0) {
    await c.query(`CREATE DATABASE "${nome}"`);
    console.log("banco " + nome + " criado");
  } else {
    console.log("banco " + nome + " ja existe");
  }
  await c.end();
})().catch((e) => { console.error("bootstrap falhou: " + e.message); process.exit(1); });
'
