# BitToHub
Script para  migração do Bitbucket para o GitHub.

Segue a documentação completa do script de migração de repositórios do Bitbucket para o GitHub, incluindo explicações de variáveis, funções e funcionalidades.

---

# Documentação do Script de Migração de Repositórios Bitbucket para GitHub

## Descrição

Este script automatiza a migração de repositórios do Bitbucket para o GitHub. Ele verifica se os repositórios já existem no GitHub e, se necessário, cria ou atualiza o repositório no GitHub. O processo é executado em paralelo para otimizar o tempo de execução e inclui logs detalhados sobre cada etapa do processo.

---

## Pré-requisitos

1. **Autenticação configurada** para o GitHub CLI (`gh`) e o Bitbucket.
2. **GitHub CLI (`gh`)** deve estar instalado e autenticado com permissões para criar e atualizar repositórios na organização especificada.
3. **Arquivo de lista de repositórios (`repos.txt`)** com o nome de cada repositório que será migrado, um nome por linha.

---

## Variáveis

- **`BITBUCKET_WORKSPACE`**: Nome do workspace no Bitbucket.
- **`ORG_NAME`**: Nome da organização no GitHub.
- **`REPOS_FILE`**: Nome do arquivo de texto contendo a lista de repositórios a serem migrados.
- **`LOG_FILE`**: Nome do arquivo de log para armazenar logs da execução.
- **`SKIP_FILE`**: Nome do arquivo de log para listar repositórios ignorados devido ao tamanho de arquivos grandes.
- **`MAX_PARALLEL`**: Limite de processos que serão executados em paralelo para otimização.

---

## Funções

### 1. `log`
**Descrição**: Registra mensagens de log com timestamp.

**Sintaxe**: `log "Mensagem para log"`

### 2. `check_bitbucket_repo_exists`
**Descrição**: Verifica se um repositório existe no Bitbucket.

**Sintaxe**: `check_bitbucket_repo_exists "nome_do_repositorio"`

### 3. `check_github_repo_exists`
**Descrição**: Verifica se um repositório existe no GitHub.

**Sintaxe**: `check_github_repo_exists "nome_do_repositorio"`

### 4. `create_github_repo`
**Descrição**: Cria um repositório privado na organização do GitHub.

**Sintaxe**: `create_github_repo "nome_do_repositorio"`

### 5. `get_last_commit_hash`
**Descrição**: Obtém o hash do último commit de um repositório remoto.

**Sintaxe**: `get_last_commit_hash "url_do_repositorio"`

### 6. `check_large_files`
**Descrição**: Verifica se o repositório contém arquivos maiores que 100 MB.

**Sintaxe**: `check_large_files`

### 7. `process_repo`
**Descrição**: Função principal que processa um único repositório:
   - Verifica se o repositório existe no Bitbucket.
   - Cria o repositório no GitHub caso não exista.
   - Clona o repositório do Bitbucket localmente e faz push para o GitHub, caso o repositório precise ser atualizado.

**Sintaxe**: `process_repo "nome_do_repositorio"`

---

## Execução em Paralelo

O script usa `xargs` para processar cada repositório em subprocessos paralelos, limitando a quantidade de processos simultâneos com o valor definido em `MAX_PARALLEL`.

---

## Contagem de Repositórios Migrados e Atualizados

1. **Arquivos Temporários**:
   - `MIGRATED_COUNT_FILE`: Incrementado sempre que um novo repositório é criado no GitHub.
   - `UPDATED_COUNT_FILE`: Incrementado sempre que um repositório no GitHub é atualizado para a versão do Bitbucket.

2. **Contagem Final**:
   - No final da execução, o script calcula o total de repositórios migrados e atualizados e exibe o resumo.

---

## Logs

Todos os logs são armazenados no arquivo `processamento.log`, com informações sobre cada etapa:
- Criação e atualização de repositórios.
- Erros, como falhas ao acessar diretórios ou repositórios não encontrados.
- Repositórios ignorados devido a arquivos grandes, armazenados em `repositorios_ignorados.log`.

---

## Como Executar

1. Configure as variáveis do script para refletir suas credenciais e configurações de repositório.
2. Execute o script com permissão de execução:
   ```bash
   chmod +x script_migracao.sh
   ./script_migracao.sh
   ```

---

## Exemplo de Saída do Log

```
[2024-11-09 10:00:00] Iniciando processamento do repositório exemplo-repo...
[2024-11-09 10:00:01] Repositório exemplo-repo não encontrado no GitHub. Criando...
[2024-11-09 10:00:05] Clonando exemplo-repo de git@bitbucket.org:metropoles/exemplo-repo.git para atualização
[2024-11-09 10:00:15] Repositório exemplo-repo migrado com sucesso para GitHub.
[2024-11-09 10:00:16] Processamento do repositório exemplo-repo concluído.
```

---

## Conclusão

Este script oferece uma solução automatizada para a migração de repositórios do Bitbucket para o GitHub com logs detalhados, contagem de repositórios migrados e controle de subprocessos para melhor desempenho.
