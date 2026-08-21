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
- `DISABLE_ENTERPRISE=true` para um fork community/white-label sem módulos enterprise
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
docker compose -f docker-compose.production.yaml up -d
```

## Deploy pelo Dokploy: migração antes da aplicação

Use `docker-compose.production.yaml` como o Compose do serviço no Dokploy e mantenha o comando padrão de deploy. Não preencha **Advanced → Command** e não acrescente a migração aos comandos de `rails` ou `sidekiq`.

O Compose declara o serviço `migration`, que executa uma única vez, com a mesma imagem e variáveis da aplicação:

```sh
RAILS_ENV=production bundle exec rails db:chatwoot_prepare
```

Os serviços `rails` e `sidekiq` usam `depends_on` com `service_completed_successfully`. Portanto, a cada deploy em que a imagem é recriada, o Dokploy cria e aguarda esse único job; só depois inicia os dois processos. Se a migração falhar, o deploy para antes de liberar a versão nova.

## Rollback

1. No Dokploy, selecione a imagem/commit anterior e execute o redeploy.
2. Confirme que o job `migration` terminou com sucesso antes de liberar Rails e Sidekiq.
3. Se a versão nova alterou o schema de forma incompatível ou irreversível, restaure o backup do PostgreSQL feito antes do deploy; não execute `db:rollback` automaticamente.

## Melhorias recomendadas pela comunidade

- Evitar `chatwoot/chatwoot:latest` em produção. Build do fork local ou tag fixa reduz risco de upgrade surpresa.
- Rodar sempre `rails db:chatwoot_prepare` antes de subir alterações de versão.
- Manter `postgres` e `redis` expostos apenas em `127.0.0.1` ou remover as portas se não houver acesso externo.
- Colocar Nginx ou Traefik na frente com TLS e `FRONTEND_URL` em `https`.
- Fazer backup recorrente de `storage`, banco e variáveis sensíveis.
- Considerar Postgres e Redis gerenciados se o ambiente for crítico.
- Fixar um processo claro de atualização do fork: `git fetch`, checkout de tag/branch aprovada, rebuild, migrate, deploy.
