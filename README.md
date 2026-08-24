# Tarsila - Agenda

Agenda Tarsila é um calendário leve em GTK3 com sincronização opcional com o
Google Agenda.

**Sem login funciona**: existe um calendário local ("Minha agenda"), criado no
primeiro uso, que não depende de conta nenhuma. O Google é um extra, não um
requisito — quem nunca entrar continua com uma agenda inteira e utilizável.

## Construir

```
./build-deb.sh
```

Gera `agenda-tarsila_<versão>_all.deb`. A versão sai do `DEBIAN/control`, que é
a fonte única — não escreva o número em outro lugar.

## As credenciais do Google

### As duas coisas que não se confundem

| arquivo | identifica | vem no pacote? |
|---|---|---|
| `credentials.json` | **o aplicativo** (`client_id` + `client_secret`) | sim, se você puser |
| `token.json` | **a conta da pessoa** (`refresh_token`) | **nunca** |

O `token.json` nasce no login e mora em `~/.config/agenda-tarsila/` de cada
usuário. Não existe "já vem logado": a pessoa sempre escolhe a conta dela. O que
o `credentials.json` poupa é ela ter que **criar um projeto no Google Cloud**,
que é o passo onde qualquer leigo desiste.

### Como embarcar

O `build-deb.sh` copia `src/` inteiro, e o aplicativo procura o arquivo em
`/etc/agenda-tarsila/credentials.json`. Então basta, **na máquina de build**:

```
mkdir -p src/etc/agenda-tarsila
cp ~/onde-voce-guarda/credentials.json src/etc/agenda-tarsila/credentials.json
./build-deb.sh
```

O `.gitignore` barra `credentials.json` (e a versão `.gpg`), então o arquivo não
entra no Git nem por acidente. Se ele não estiver lá na hora do build, o script
avisa e segue: o pacote sai sem a credencial e a Agenda pede o arquivo na tela
de login.

Tem de ser um cliente OAuth do tipo **"App para desktop"**. Um do tipo
"Aplicativo Web" é recusado com mensagem explícita — o fluxo usado aqui é o de
loopback em `127.0.0.1`, que é o atual; o antigo fluxo "oob" foi descontinuado
pelo Google.

### O estado hoje: "Testing" — leia antes de prometer

O escopo usado é `auth/calendar`, que o Google classifica como **sensível**.
Enquanto a tela de consentimento estiver em **Testing**:

- **Só as contas que você adicionar à mão** na lista de *test users* do Cloud
  Console conseguem autorizar. Qualquer outra recebe `Error 403: access_denied`.
  Não é cota, é lista de permissão: o padrão é negar, e ser um projeto pequeno
  não ajuda em nada.
- O **`refresh_token` expira em ~7 dias**. O código lida bem — o
  `silent_login()` falha calado, marca como não autenticado e o botão de login
  reaparece —, mas a pessoa refaz o login toda semana.

Por isso: **não anuncie "Agenda já conectada ao Google"** enquanto estiver em
Testing. Prometer uma conexão que dá erro na cara do cliente é pior do que não
prometer nada. O calendário local é o que se promete hoje.

Estas regras são política do Google e mudam com o tempo. Para conferir o estado
de verdade, o teste que decide leva dois minutos: tente o login com um Gmail que
**não** esteja na lista de test users e veja o que aparece.

### Quando a verificação sair

Trocar a credencial é trocar o arquivo e reconstruir o pacote — não há código
envolvido. Um detalhe do qual lembrar:

> O `token.json` de cada usuário guarda o `client_id` e o `client_secret`
> **dentro dele**. As caixas já instaladas continuam usando a credencial antiga e
> seguem funcionando enquanto aquele cliente OAuth existir no console. Se você
> apagar o cliente antigo, elas quebram e pedem um login novo (uma vez só).
>
> Então: mantenha o cliente antigo vivo por um tempo depois da troca, para as
> caixas migrarem sozinhas conforme as pessoas refazem o login.

## Onde o aplicativo procura o `credentials.json`

Na ordem:

1. `~/.config/agenda-tarsila/credentials.json` — o que a pessoa escolher pela
   tela de login ("Selecionar credentials.json...")
2. `/etc/agenda-tarsila/credentials.json` — o que vem no pacote, para todos
3. `/opt/agenda-tarsila/credentials.json`

## Arquivos por usuário

```
~/.config/agenda-tarsila/token.json        sessão do Google (nasce no login)
~/.config/agenda-tarsila/settings.json     preferências
~/.config/agenda-tarsila/credentials.json  cliente OAuth próprio (opcional)
~/.local/share/agenda-tarsila/cache.db     cache dos eventos
```
