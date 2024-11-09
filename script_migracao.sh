#!/bin/bash

# Defina as variáveis
BITBUCKET_WORKSPACE="Nome do Workspace BitBucket"
ORG_NAME="Nome da Organização GitHub"
REPOS_FILE="repos.txt"
LOG_FILE="processamento.log"
SKIP_FILE="repositorios_ignorados.log"
MAX_PARALLEL=5  # Limite de processos paralelos

# Arquivos temporários para contagem
MIGRATED_COUNT_FILE="migrated_count.tmp"
UPDATED_COUNT_FILE="updated_count.tmp"
> "${MIGRATED_COUNT_FILE}"
> "${UPDATED_COUNT_FILE}"

# Cria os arquivos de log, se não existirem
touch "${LOG_FILE}"
touch "${SKIP_FILE}"

# Função para log com timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Função para verificar se um repositório existe no Bitbucket
check_bitbucket_repo_exists() {
    local BITBUCKET_URL="git@bitbucket.org:${BITBUCKET_WORKSPACE}/${1}.git"
    git ls-remote "${BITBUCKET_URL}" &> /dev/null
    return $?
}

# Função para verificar se um repositório existe no GitHub
check_github_repo_exists() {
    gh repo view "${ORG_NAME}/${1}" &> /dev/null
    return $?
}

# Função para criar um repositório privado no GitHub
create_github_repo() {
    local REPO_NAME=$1
    log "\e[32mIniciando criação do repositório ${REPO_NAME} no GitHub...\e[0m"
    gh repo create "${ORG_NAME}/${REPO_NAME}" --private --confirm | tee -a "${LOG_FILE}"
}

# Função para obter o hash do último commit de um repositório remoto
get_last_commit_hash() {
    local REPO_URL=$1
    git ls-remote "${REPO_URL}" HEAD | awk '{print $1}'
}

# Função para verificar se existem arquivos maiores que 100MB
check_large_files() {
    find . -type f -size +100M | grep -q .
}

# Verifique se o arquivo com a lista de repositórios existe
if [[ ! -f "${REPOS_FILE}" ]]; then
    log "Arquivo ${REPOS_FILE} não encontrado."
    exit 1
fi

# Função para processar um único repositório
process_repo() {
    local REPO_NAME=$1

    BITBUCKET_URL="git@bitbucket.org:${BITBUCKET_WORKSPACE}/${REPO_NAME}.git"
    GITHUB_URL="git@github.com:${ORG_NAME}/${REPO_NAME}.git"

    log "\e[34mIniciando processamento do repositório ${REPO_NAME}...\e[0m"

    # Ignorar repositórios que já foram marcados com arquivos grandes
    if grep -Fxq "$REPO_NAME" "$SKIP_FILE"; then
        log "\e[33mIgnorando ${REPO_NAME}: contém arquivos grandes (já registrado).\e[0m"
        return
    fi

    if ! check_bitbucket_repo_exists "$REPO_NAME"; then
        log "\e[31mRepositório ${REPO_NAME} não encontrado no Bitbucket.\e[0m"
        return
    fi

    if check_github_repo_exists "$REPO_NAME"; then
        log "\e[32mRepositório ${ORG_NAME}/${REPO_NAME} já existe no GitHub. Verificando atualização...\e[0m"
        BITBUCKET_COMMIT_HASH=$(get_last_commit_hash "$BITBUCKET_URL")
        GITHUB_COMMIT_HASH=$(get_last_commit_hash "$GITHUB_URL")
        
        if [[ "$BITBUCKET_COMMIT_HASH" == "$GITHUB_COMMIT_HASH" ]]; then
            log "\e[32mRepositório ${REPO_NAME} no GitHub já está atualizado.\e[0m"
            return
        fi

        # Incrementa contador de repositórios atualizados
        echo 1 >> "${UPDATED_COUNT_FILE}"
    else
        # Criar o repositório no GitHub se ele não existir
        create_github_repo "$REPO_NAME"
        
        # Incrementa contador de repositórios migrados
        echo 1 >> "${MIGRATED_COUNT_FILE}"
    fi

    log "\e[34mClonando ${REPO_NAME} de ${BITBUCKET_URL} para atualização\e[0m"
    git clone --mirror "${BITBUCKET_URL}" "${REPO_NAME}.git" | tee -a "${LOG_FILE}"

    cd "${REPO_NAME}.git" || { log "\e[31mErro ao acessar diretório ${REPO_NAME}.git\e[0m"; return; }

    if check_large_files; then
        log "\e[31mRepositório ${REPO_NAME} contém arquivos maiores que 100MB. Ignorando em futuras execuções.\e[0m"
        echo "$REPO_NAME" >> "$SKIP_FILE"
        cd .. && rm -rf "${REPO_NAME}.git"
        return
    fi

    log "\e[32mPushing o repositório ${REPO_NAME} para GitHub...\e[0m"
    git remote add origin "${GITHUB_URL}"
    git push --mirror origin | tee -a "${LOG_FILE}"

    cd .. && rm -rf "${REPO_NAME}.git"
    log "\e[34mProcessamento do repositório ${REPO_NAME} concluído.\e[0m"
}

export -f log process_repo check_bitbucket_repo_exists check_github_repo_exists create_github_repo get_last_commit_hash check_large_files

# Processar repositórios em paralelo com limite de subprocessos
cat "${REPOS_FILE}" | xargs -n 1 -P "${MAX_PARALLEL}" -I {} bash -c 'process_repo "$@"' _ {}

# Exibir contagem final de repositórios migrados e atualizados
MIGRATED_REPOS=$(wc -l < "${MIGRATED_COUNT_FILE}")
UPDATED_REPOS=$(wc -l < "${UPDATED_COUNT_FILE}")
log "\e[36mMigração concluída: ${MIGRATED_REPOS} repositórios migrados, ${UPDATED_REPOS} repositórios atualizados.\e[0m"

# Limpar arquivos temporários
rm -f "${MIGRATED_COUNT_FILE}" "${UPDATED_COUNT_FILE}"
