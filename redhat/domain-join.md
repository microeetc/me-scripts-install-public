### README: Script de Integração AD (Red Hat Edition)

Este README descreve o funcionamento do script para distribuições baseadas em Red Hat (RHEL, AlmaLinux, Rocky Linux).

### Diferenciais desta versão:

* **Crypto Policies:** Ativa o suporte a algoritmos legados necessários para alguns ambientes AD (`AD-SUPPORT`).
* **AuthSelect:** Utiliza o comando nativo do RHEL para configurar o PAM e a criação de Home Directories (`with-mkhomedir`).
* **Gerenciamento de Pacotes:** Utiliza `dnf` e os nomes de pacotes específicos da família Red Hat (como `krb5-workstation`).

### Como Executar

#### 1. Via Parâmetros (Linha de comando)

```bash
sudo ./redhat.sh --domain domain.local --user username --groups "linuxadmins grexample2"

```

#### 2. Execução Direta via URL (Pipe)

Mesmo sendo Red Hat, você pode rodar o script diretamente do seu repositório sem baixar o arquivo primeiro:

```bash
wget -qO- https://raw.githubusercontent.com/microeetc/me-scripts-install-public/master/domain-join/redhat.sh | bash -s -- --domain domain.local --user username --groups "linuxadmins grexample2"

```

#### 3. Modo Interativo

Se nenhum parâmetro for passado, o script perguntará os dados:

```bash
sudo ./redhat.sh

```

### Comandos de Limpeza (Troubleshooting)

Se precisar limpar o cache ou remover a máquina do domínio:

* **Limpar Cache SSSD:** `sudo rm -f /var/lib/sss/db/* && sudo systemctl restart sssd`
* **Sair do Domínio:** `sudo realm leave domain.local`
