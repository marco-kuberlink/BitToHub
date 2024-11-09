# Projeto: Sincronização de Repositórios Bitbucket para GitHub

## Descrição
Este script em Bash é utilizado para sincronizar repositórios entre Bitbucket e GitHub, verificando a existência dos repositórios em ambas as plataformas, clonando do Bitbucket e espelhando para o GitHub. O script controla a execução simultânea de subprocessos e registra operações em arquivos de log para monitorar o progresso e o estado de cada repositório.

## Estrutura do Projeto
- **`repos.txt`**: Arquivo de entrada com a lista de nomes dos repositórios no Bitbucket a serem processados.
- **`processamento.log`**: Arquivo de log para registrar o status e os resultados das operações de sincronização.
- **`repositorios_ignorados.log`**: Arquivo para registrar os repositórios que foram ignorados devido à presença de arquivos grandes (acima de 100MB).

## Funcionalidades do Script
1. **Verificação de Existência no Bitbucket**: Valida se o repositório existe no Bitbucket antes de qualquer operação.
2. **Verificação de Existência no GitHub**: Confirma se o repositório já existe no GitHub.
3. **Clonagem e Atualização**: Clona o repositório do Bitbucket em modo espelho e atualiza se ele já existe localmente.
4. **Verificação de Arquivos Grandes**: Ignora repositórios que contenham arquivos maiores que 100MB, registrando-os em um arquivo separado.
5. **Sincronização com GitHub**: Cria o repositório no GitHub, se necessário, e empurra todas as alterações para ele.
6. **Controle de Subprocessos**: Limita o número de operações simultâneas, evitando sobrecarga do sistema.

## Variáveis de Ambiente
- `BITBUCKET_WORKSPACE`: Define o workspace do Bitbucket.
- `ORG_NAME`: Nome da organização no GitHub.
- `LOG_FILE`: Arquivo onde logs serão armazenados.
- `SKIP_FILE`: Arquivo de registro dos repositórios ignorados.
- `MAX_JOBS`: Define o número máximo de subprocessos simultâneos.

## Instruções de Uso
1. **Configuração Inicial**: Defina as variáveis `BITBUCKET_WORKSPACE` e `ORG_NAME` com os valores apropriados.
2. **Criar Arquivos Necessários**: Certifique-se de que `repos.txt` contenha uma lista dos repositórios que deseja sincronizar.
3. **Execução do Script**: Execute o script no terminal com o comando:
   ```bash
   ./script_migracao.sh
   ```
4. **Monitoramento**: Acompanhe o arquivo `processamento.log` para verificar o progresso e `repositorios_ignorados.log` para os repositórios ignorados.

## Exemplo de Configuração do `repos.txt`
```plaintext
repositório1
repositório2
repositório3
```

## Notas
- É importante garantir que os comandos `git` e `gh` (GitHub CLI) estejam instalados e configurados com as credenciais apropriadas.
- O script exclui os repositórios clonados localmente após cada execução para economizar espaço em disco.
