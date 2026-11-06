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

Regra de horário: o primeiro início de rota do dia só é aceito de segunda a sexta, das
07:00 às 17:00 (America/Fortaleza). Fora disso o servidor responde 409 e o app mostra o
botão desabilitado; depois de iniciada, a rota segue utilizável (fotos, check-in,
finalizar) mesmo após as 17:00, exceto retomar uma rota pausada ou pedir novo lote, que
também ficam barrados depois das 17:00. Os limites ficam em `system_settings`, editáveis
pelo administrador.

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

### Banco de testes

Um segundo banco, só para os **testes manuais** do autor com o app e o painel, em qualquer
dia e horário. A regra de horário (07:00–17:00, seg–sex) vale no banco real; o banco de
testes a desliga por configuração própria: o seed dele grava expediente `00:00:00`–`23:59:59`,
todos os dias da semana e raio de presença de 25 m. Não existe "modo teste" no código: a
exceção são **só dados** desse banco e não alcança o real. Não serve para pytest, vitest nem
CI.

```bash
./infra/scripts/dev-up-test.sh            # sobe (cria o banco de testes na primeira vez)
./infra/scripts/dev-up-test.sh --reset    # apaga o banco de testes e recria do zero
```

- Projeto compose separado (`route-monitor-test`), volumes próprios; recusa rodar com a stack
  real de pé (mesmas portas): derrube o `dev-up.sh` antes. `Ctrl+C` derruba os containers e
  mantém o volume.
- Cinco prédios reais do OpenStreetMap (Casa 1 a 5, de 1 a 3 salas cada) em volta da Rua
  Raimundo da Silva Ribeiro, Tambor, Campina Grande. O retângulo do campus é o das casas mais
  500 m.
- Mapa e roteamento próprios, gerados por `infra/scripts/build-test-map.sh` em `infra/data-test/`
  (não versionado) na primeira subida. Precisa do extrato do Nordeste: rode antes
  `./infra/scripts/fetch-osm.sh` (ver "Dados de mapa").
- Logins: os mesmos do seed real (senha `trocar-esta-senha`). O seed imprime a chave pública
  dos QR Codes e a linha de `flutter run` pronta.
- "Uma vez por dia" continua valendo: depois de iniciar e finalizar, o botão fica desabilitado.
  Para repetir, recrie o banco com `--reset`.
- As "24 h" do banco de testes são, na prática, `00:00:00`–`23:59:58`: às 23:59:59 a trava de
  fim de expediente (`>=`) ainda vale.
- A stack de testes mantém o agendador de alertas e as regras de liberação por silêncio
  ligados: numa rodada manual um ponto pode ser liberado após 45 minutos sem GPS, e as rotas
  abertas são encerradas no fim do dia (23:59:59).

App apontando para o banco de testes (o mapa embarcado `assets/tambor.pmtiles` e o centro
são escolhidos na compilação):

```bash
cd mobile
flutter run --dart-define=API_BASE_URL=http://<ip-da-máquina>:8000 \
            --dart-define=QR_PUBLIC_KEY_HEX=<valor impresso pelo seed> \
            --dart-define=CAMPUS_TILES_ASSET=assets/tambor.pmtiles \
            --dart-define=CAMPUS_CENTER=-7.25561775,-35.888482125
```

No emulador Android, `API_BASE_URL=http://10.0.2.2:8000`, e o GPS se simula com
`adb emu geo fix <lng> <lat>` (longitude primeiro), por exemplo
`adb emu geo fix -35.888482 -7.255618`. A leitura de QR Code continua pedindo aparelho
físico. O painel enquadra o mapa pelo `VITE_CAMPUS_BBOX`, que o compose de testes já define.

Limitações conhecidas dos dados:

- O OpenStreetMap é esparso perto do endereço: os cinco contornos são `building=yes` (não
  confirmados como residenciais) e quatro deles ficam a ~450–490 m do centro.
- O número 359 não existe no OSM. O centro é o centróide da way 1195393305 (ver
  `center_note` em `backend/app/seed_data/tambor_buildings.json`).
- `infra/data-test/` é criado pelo Docker como root; apagar exige `sudo`.

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
