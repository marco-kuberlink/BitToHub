#!/bin/bash

# Variáveis
BITBUCKET_WORKSPACE="bitbucket_workspace"
ORG_NAME="Organização_BitBucket"
REPOS_FILE="repos.txt"
LOG_FILE="${LOG_FILE:-processamento.log}"
SKIP_FILE="${SKIP_FILE:-repositorios_ignorados.log}"
MAX_JOBS=5  # Define o número máximo de subprocessos em execução ao mesmo tempo

# Garantindo que os arquivos de log estão definidos corretamente
touch "${LOG_FILE}" || { echo "Erro ao criar o arquivo de log."; exit 1; }
touch "${SKIP_FILE}" || { echo "Erro ao criar o arquivo de repositórios ignorados."; exit 1; }

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

# Função para criar um repositório privado no GitHub e verificar sua criação
create_and_confirm_github_repo() {
    local REPO_NAME=$1
    echo -e "\e[32mIniciando criação do repositório ${REPO_NAME} no GitHub...\e[0m" | tee -a "${LOG_FILE}"
    gh repo create "${ORG_NAME}/${REPO_NAME}" --private -y | tee -a "${LOG_FILE}"

    # Verificar até que o repositório esteja disponível no GitHub
    local MAX_RETRIES=5
    local COUNT=0
    while ! check_github_repo_exists "$REPO_NAME"; do
        if (( COUNT >= MAX_RETRIES )); then
            echo -e "\e[31mFalha ao criar o repositório ${REPO_NAME} no GitHub após várias tentativas.\e[0m" | tee -a "${LOG_FILE}"
            return 1
        fi
        echo "Aguardando confirmação de criação do repositório no GitHub... (tentativa $((++COUNT)))"
        sleep 2
    done
    return 0
}

# Processamento de cada repositório
process_repo() {
    local REPO_NAME="$1"
    echo -e "\n[ $(date +'%Y-%m-%d %H:%M:%S') ] Iniciando processamento do repositório ${REPO_NAME}..." | tee -a "${LOG_FILE}"

    BITBUCKET_URL="git@bitbucket.org:${BITBUCKET_WORKSPACE}/${REPO_NAME}.git"
    GITHUB_URL="git@github.com:${ORG_NAME}/${REPO_NAME}.git"

    # Ignorar repositórios que já foram marcados com arquivos grandes
    if grep -Fxq "$REPO_NAME" "$SKIP_FILE"; then
        echo -e "\e[33mIgnorando ${REPO_NAME} devido a arquivos grandes (já registrado).\e[0m" | tee -a "${LOG_FILE}"
        return
    fi

    # Verificar existência do repositório no Bitbucket antes de tentar qualquer operação
    if ! check_bitbucket_repo_exists "$REPO_NAME"; then
        echo -e "\e[31mRepositório ${REPO_NAME} não encontrado no Bitbucket.\e[0m" | tee -a "${LOG_FILE}"
        return
    fi

    # Clonar e verificar o repositório
    if [[ -d "${REPO_NAME}.git" ]]; then
        echo -e "\e[33mAtualizando repositório local ${REPO_NAME}.git\e[0m" | tee -a "${LOG_FILE}"
        cd "${REPO_NAME}.git" || return
        git fetch --all | tee -a "${LOG_FILE}"
    else
        echo -e "\e[34mClonando ${REPO_NAME} de ${BITBUCKET_URL}\e[0m" | tee -a "${LOG_FILE}"
        git clone --mirror "${BITBUCKET_URL}" | tee -a "${LOG_FILE}"
        cd "${REPO_NAME}.git" || { echo -e "\e[31mErro ao acessar diretório ${REPO_NAME}.git\e[0m" | tee -a "${LOG_FILE}"; return; }
    fi

    # Verificar arquivos grandes antes de prosseguir
    if check_large_files; then
        cd .. && rm -rf "${REPO_NAME}.git"  # Remove o repositório local
        return
    fi

    # Sincronizar com o GitHub
    if check_github_repo_exists "$REPO_NAME"; then
        BITBUCKET_COMMIT_HASH=$(git ls-remote "$BITBUCKET_URL" HEAD | awk '{print $1}')
        GITHUB_COMMIT_HASH=$(git ls-remote "$GITHUB_URL" HEAD | awk '{print $1}')
        if [[ "$BITBUCKET_COMMIT_HASH" != "$GITHUB_COMMIT_HASH" ]]; then
            echo -e "\e[32mRepositório ${REPO_NAME} no GitHub desatualizado. Atualizando...\e[0m" | tee -a "${LOG_FILE}"
            git remote remove origin
            git remote add origin "${GITHUB_URL}"
            git push --mirror origin | tee -a "${LOG_FILE}"
        else
            echo -e "\e[32mRepositório ${REPO_NAME} no GitHub já está atualizado.\e[0m" | tee -a "${LOG_FILE}"
        fi
    else
        if create_and_confirm_github_repo "$REPO_NAME"; then
            git remote add origin "${GITHUB_URL}"
            git push --mirror origin | tee -a "${LOG_FILE}"
        else
            echo -e "\e[31mFalha ao criar o repositório ${REPO_NAME} no GitHub.\e[0m" | tee -a "${LOG_FILE}"
        fi
    fi

    cd .. && rm -rf "${REPO_NAME}.git"
}

# Contador de subprocessos em execução
current_jobs=0

# Processa cada repositório
while IFS= read -r REPO_NAME || [[ -n "$REPO_NAME" ]]; do
    # Executa o processamento em background
    process_repo "$REPO_NAME" &

    # Incrementa o contador de subprocessos
    current_jobs=$((current_jobs + 1))

    # Controla o número máximo de jobs simultâneos
    if [[ "$current_jobs" -ge "$MAX_JOBS" ]]; then
        # Aguarda todos os subprocessos terminarem antes de continuar
        wait
        current_jobs=0
    fi
done < "$REPOS_FILE"

# Aguarda que todos os subprocessos finalizem antes de encerrar o script
wait
