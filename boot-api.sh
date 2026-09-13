#!/bin/sh
# Sobe a API registrando tudo em /srv/boot.log. Se ela morrer, um servidor
# minimo assume a porta e devolve o log — este EasyPanel nao tem endpoint de
# log (queryServiceLogs depende de Loki, que nao esta instalado), entao sem
# isto um crash-loop e invisivel.
mkdir -p /srv
{
  echo "### bootstrap do banco"
  sh /repo/bootstrap-db.sh 2>&1
  echo "bootstrap_exit=$?"
  echo
  echo "### migrate deploy"
  cd /repo/packages/db || exit 1
  bunx prisma migrate deploy 2>&1
  echo "migrate_exit=$?"
  echo
  echo "### start:prod"
  cd /repo/apps/api || exit 1
  bun run start:prod 2>&1
  echo "api_exit=$?"
} >> /srv/boot.log 2>&1

exec node -e "const fs=require('fs');require('http').createServer((q,s)=>{s.writeHead(200,{'content-type':'text/plain; charset=utf-8'});s.end('API CAIU — log do boot:\n\n'+fs.readFileSync('/srv/boot.log','utf8'))}).listen(process.env.PORT||3001)"
