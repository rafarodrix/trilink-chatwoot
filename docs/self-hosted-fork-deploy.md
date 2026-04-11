# Deploy do Chatwoot a partir do fork

Este fluxo usa o código local do fork `https://github.com/rafarodrix/chatwoot.git` para gerar a imagem Docker de produção.

## Local sugerido de instalação

Use um diretório estável no servidor, por exemplo:

```bash
/srv/chatwoot/rafarodrix/chatwoot
```

Exemplo de clone:

```bash
git clone https://github.com/rafarodrix/chatwoot.git /srv/chatwoot/rafarodrix/chatwoot
cd /srv/chatwoot/rafarodrix/chatwoot
```

## Arquivos usados

- `docker-compose.production.yaml`: sobe a stack de produção buildando do código local.
- `.env`: variáveis da aplicação.

## Ajustes mínimos no `.env`

Copie o template e ajuste pelo menos:

```bash
cp .env.example .env
```

Defina:

- `RAILS_ENV=production`
- `FRONTEND_URL=https://seu-dominio`
- `SECRET_KEY_BASE=...`
- `POSTGRES_PASSWORD=...`
- `REDIS_PASSWORD=...`
- chaves `ACTIVE_RECORD_ENCRYPTION_*` se for usar MFA/2FA

Variáveis opcionais do compose:

- `CHATWOOT_IMAGE_NAME=rafarodrix/chatwoot:prod`
- `CHATWOOT_BIND_IP=127.0.0.1`
- `CHATWOOT_WEB_PORT=3000`
- `POSTGRES_EXPOSE_PORT=5432`
- `REDIS_EXPOSE_PORT=6379`

## Subida inicial

```bash
docker compose -f docker-compose.production.yaml build
docker compose -f docker-compose.production.yaml run --rm rails bundle exec rails db:chatwoot_prepare
docker compose -f docker-compose.production.yaml up -d
```

## Melhorias recomendadas pela comunidade

- Evitar `chatwoot/chatwoot:latest` em produção. Build do fork local ou tag fixa reduz risco de upgrade surpresa.
- Rodar sempre `rails db:chatwoot_prepare` antes de subir alterações de versão.
- Manter `postgres` e `redis` expostos apenas em `127.0.0.1` ou remover as portas se não houver acesso externo.
- Colocar Nginx ou Traefik na frente com TLS e `FRONTEND_URL` em `https`.
- Fazer backup recorrente de `storage`, banco e variáveis sensíveis.
- Considerar Postgres e Redis gerenciados se o ambiente for crítico.
- Fixar um processo claro de atualização do fork: `git fetch`, checkout de tag/branch aprovada, rebuild, migrate, deploy.
