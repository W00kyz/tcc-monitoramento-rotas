# Sistema de Monitoramento de Rotas e Execução de Serviços

Prefeitura Universitária da UFCG. Trabalho de Conclusão de Curso de Marcos Antônio
Cardoso Pereira, orientado por Eliane Cristina de Araújo.

Monitora a execução de serviços terceirizados no campus: os profissionais registram
presença lendo QR Codes fixados nos andares, cruzados com GPS, e os gestores
acompanham rotas, alertas e relatórios por um painel web.

## Componentes

| Diretório | Repositório | Stack |
|---|---|---|
| `backend/` | [tcc-backend](https://github.com/W00kyz/tcc-backend) | FastAPI, PostgreSQL/PostGIS |
| `dashboard/` | [tcc-dashboard](https://github.com/W00kyz/tcc-dashboard) | React, TypeScript, Vite |
| `mobile/` | [tcc-mobile](https://github.com/W00kyz/tcc-mobile) | Flutter (Android) |
| `infra/` | este repositório | Docker Compose, OSRM, PMTiles |

## Inicialização

Requer Docker, OpenSSL e [mise](https://mise.jdx.dev).

```bash
git clone --recurse-submodules https://github.com/W00kyz/tcc-monitoramento-rotas.git
cd tcc-monitoramento-rotas
./infra/scripts/dev-up.sh
```

O script cria `infra/.env` a partir de `infra/.env.sample` (se ainda não existir), gera
a chave de assinatura dos QR Codes e o segredo do JWT no lugar dos placeholders, sobe
os containers (o backend aplica as migrações sozinho ao iniciar), roda o seed com dados
de exemplo e fica mostrando os logs. `Ctrl+C` derruba tudo; os dados ficam nos volumes.

| Serviço | Endereço |
|---|---|
| API | http://localhost:8000 · docs em `/docs` |
| Painel | http://localhost:5173 |
| MinIO | http://localhost:9001 |
| Mailpit | http://localhost:8025 — convites e e-mails de recuperação de senha |

Usuários do seed (senha `trocar-esta-senha`):

| Perfil | E-mail |
|---|---|
| Administrador | `admin@pu.ufcg.edu.br` |
| Gestora | `larissa@pu.ufcg.edu.br` |
| Profissional de campo | `joao@empresa.com` |

Novos usuários criados pelo administrador recebem um convite por e-mail (no Mailpit) com
o link para definir a senha.

Sem o script, o equivalente manual é:

```bash
cp infra/.env.sample infra/.env    # preencher QR_SIGNING_PRIVATE_KEY_HEX e JWT_SECRET_KEY
docker compose -f infra/docker-compose.yml up -d --build
docker compose -f infra/docker-compose.yml exec backend uv run python -m app.seed
```

Já clonou sem `--recurse-submodules`?

```bash
git submodule update --init --recursive
```

### Aplicativo mobile

Roda à parte, num Android 8.0+ físico (QR Code e GPS não funcionam em emulador), com o
backend alcançável pela rede local. O seed imprime a chave pública dos QR Codes:

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://<ip-da-máquina>:8000 \
            --dart-define=QR_PUBLIC_KEY_HEX=<valor impresso pelo seed>
```

Para o link de recuperação de senha abrir no celular, `DASHBOARD_BASE_URL` no
`infra/.env` precisa apontar para o IP da máquina, não para `localhost` — e o painel passa
a ser aberto por esse mesmo endereço, que é a única origem liberada no CORS da API.

## Dados de mapa

O roteirizador e o mapa offline são gerados a partir de um extrato do OpenStreetMap,
que **não é versionado** por tamanho. Rodar uma vez:

```bash
./infra/scripts/fetch-osm.sh
./infra/scripts/build-osrm.sh
./infra/scripts/build-pmtiles.sh
```

## Requisitos

`docs/requisitos/Documento de Requisitos.pdf` — 53 requisitos funcionais, 22 não
funcionais, 17 casos de uso.

## Versões

Todas travadas: imagens Docker por digest, GitHub Actions por SHA, dependências por
versão exata. Arquivos de lock são commitados. Nada de `latest` nem de faixas.
