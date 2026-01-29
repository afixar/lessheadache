LESSHEADACHE
============

Autor: AFIXAR
Compatibilidade: cPanel / WHM (CentOS / CloudLinux)

O LESSHEADACHE é um utilitário de resposta automática a incidentes em servidores
com WordPress, integrado ao Imunify (360 ou Antivirus).

FUNCIONAMENTO
-------------
1. O cron (a cada X horas) executa o script lessheadache-cron.sh
2. O script consulta o Imunify por arquivos maliciosos (status FOUND)
3. Identifica quais contas cPanel foram afetadas
4. Para cada conta:
   - Restaura wp-admin e wp-includes a partir de uma base limpa
   - Corrige permissões
5. Gera log em /var/log/imunify/
6. Envia notificação por e-mail

ESTRUTURA
---------
install.sh
  -> Instalador interativo (email, /home ou /home2, valida Imunify)

scripts/wp-core-refresh
  -> Restaura core do WordPress (wp-admin + wp-includes)

scripts/lessheadache-cron.sh
  -> Script executado via cron

INSTALAÇÃO
----------
1. unzip lessheadache.zip
2. cd lessheadache
3. sudo bash install.sh

CRON
----
Arquivo criado em:
/etc/cron.d/lessheadache

Execução:
A cada 3 horas

LOGS
----
/var/log/imunify/lessheadache-YYYY-MM-DD.log

OBSERVAÇÕES
-----------
- Não remove plugins ou temas
- Não altera wp-config.php
- Requer Imunify instalado
- Requer mailx para envio de e-mail

Filosofia:
Menos dor de cabeça. Resposta automática. Core limpo.
