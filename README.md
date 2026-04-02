# bySelvs Doctor

```
  |            __|        |               _ \             |              
   _ \  |  | \__ \   -_)  | \ \ / (_-<    |  |  _ \   _|   _|   _ \   _|  
 _.__/ \_, | ____/ \___| _|  \_/  ___/   ___/ \___/ \__| \__| \___/ _|   
       ___/ byselvs.dev/doctor
```

Toolbelt pessoal de scripts de terminal — instalável via `curl` e extensível com scripts `.sh` em `scripts/`.

---

## Instalação

```bash
curl -s "https://raw.githubusercontent.com/selvs-dev/bsd/main/setup/install.sh" | bash
```

O instalador irá:

1. Clonar o repositório em `~/.bsd`
2. Adicionar `~/.bsd` ao `PATH` no `.bashrc` e/ou `.zshrc` automaticamente

Após a instalação, reabra o terminal ou execute:

```bash
source ~/.bashrc   # ou source ~/.zshrc
```

---

## Uso

```bash
bsd [COMMAND] [ARGS...]
```

| Comando     | Descrição                              |
|-------------|----------------------------------------|
| `--help`    | Exibe o banner e a lista de comandos   |
| `--install` | Adiciona o `bsd` ao PATH manualmente   |
| `<script>`  | Executa um script de `scripts/<script>.sh` |

### Exemplo

```bash
bsd rdp A
```

---

## Adicionando scripts

Coloque qualquer arquivo `.sh` dentro de `scripts/` e ele será listado automaticamente no `bsd --help` e invocável como:

```bash
bsd nome-do-script [args...]
```

---

## Atualização

Para atualizar para a versão mais recente:

```bash
git -C ~/.bsd pull
```

## Desinstalação

```bash
curl -s "https://raw.githubusercontent.com/selvs-dev/bsd/main/setup/uninstall.sh" | bash
```

Ou, se o `bsd` já estiver no PATH:

```bash
bsd --uninstall
```
