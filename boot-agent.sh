#!/bin/sh
# Mesmo padrao do boot-api.sh: sobe o agente registrando tudo, e se ele morrer
# um servidor minimo assume a porta e devolve o log. Sem isso o crash-loop e
# invisivel — este EasyPanel nao tem endpoint de log.
mkdir -p /srv
{
  echo "### backend de sandbox que o eve vai escolher"
  echo "VERCEL=${VERCEL:-<vazio>}"
  docker version --format '{{.Server.Version}}' 2>&1 | head -3
  echo
  echo "### eve start"
  cd /repo/apps/agent || exit 1
  bun run start 2>&1
  echo "agent_exit=$?"
} >> /srv/boot.log 2>&1

exec node -e "const fs=require('fs');require('http').createServer((q,s)=>{s.writeHead(200,{'content-type':'text/plain; charset=utf-8'});s.end('AGENTE CAIU — log do boot:\n\n'+fs.readFileSync('/srv/boot.log','utf8'))}).listen(process.env.AGENT_PORT||2000)"
