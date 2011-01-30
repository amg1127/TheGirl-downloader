#!/bin/bash

echo "Verificando programas necessarios..."

for programas in grep wget rm date stat egrep mkdir readlink dirname head tail sed file php; do
    echo -n "'$programas'..."
    if ( "$programas" --version > /dev/null 2>&1 || [ "$?" -eq 1 ]); then
        echo -e " OK"
    else
        echo -e ' FALHOU!'
        echo "Nao foi possivel localizar o programa '$programas'."
        echo "Verifique as configuracoes do sistema."
        echo "Saindo agora..."
        exit 1
    fi
done
echo -e "O sistema esta OK.\n"
exit 0
