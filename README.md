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

Requer Docker e [mise](https://mise.jdx.dev).

```bash
git clone --recurse-submodules https://github.com/W00kyz/tcc-monitoramento-rotas.git
cd tcc-monitoramento-rotas
cp infra/.env.sample infra/.env    # preencher; nunca commitar
docker compose -f infra/docker-compose.yml up -d
```

| Serviço | Endereço |
|---|---|
| API | http://localhost:8000 · docs em `/docs` |
| Painel | http://localhost:5173 |
| MinIO | http://localhost:9001 |
| Mailpit | http://localhost:8025 |

Já clonou sem `--recurse-submodules`?

```bash
git submodule update --init --recursive
```

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
