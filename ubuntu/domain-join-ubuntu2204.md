# Script de Integração AD (Ubuntu 24.04)

Este script automatiza o processo de ingressar uma máquina Linux Ubuntu 24.04 em um domínio Active Directory (AD). Ele foi projetado para ser resiliente, tratando automaticamente dependências, sincronização de tempo e permissões de acesso.

### O que o script faz:

* **Validação de Pré-requisitos:** Testa a resolução de DNS do domínio e a comunicação com as portas essenciais (88 e 389).
* **Sincronização de Tempo:** Verifica se há divergência de horário entre a VM e o AD (essencial para o Kerberos) e força a sincronização se necessário.
* **Instalação Automática:** Instala pacotes como `sssd`, `realmd`, `adcli` e `krb5-user`.
* **Configuração de Segurança:** Ajusta o `sssd.conf` com políticas de GPO permissivas para evitar bloqueios de login.
* **Gestão de Acessos:** Configura automaticamente o `AllowGroups` no SSH e cria arquivos de permissão no `sudoers.d` para os grupos informados.

---

### Execução

#### 1. Baixe o script

```bash
wget https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/ubuntu/domain-join-ubuntu2204.sh
```

#### 2. Liberar as permissões

```bash
chmod +x ubuntu2204.sh
```

#### 3. Executar Script

Alterar as variaveis em <> para os valores reais:

```bash
sudo ./domain-join-ubuntu2204.sh --domain <domain.local> --user <username> --groups "<admin_linux_grupos1> <admin_linux_grupos2>"

```

### Requisitos Técnicos

* **SO:** Ubuntu 24.04 LTS ou Ubuntu 22.04 LTS (não testado em outras versões)
* **Rede:** A VM deve ser capaz de alcançar os controladores de domínio e resolver o nome do domínio via DNS.
* **Privilégios:** Deve ser executado com `sudo`.

