#!/bin/bash

autenticou="0"
wget_comum="--referer='http://www.terra.com.br/thegirl' --user-agent='Mozilla/5.0 (X11; U; Linux i686; pt-BR; rv:1.7.12) Gecko/20051010 Firefox/1.0.4 (Ubuntu package 1.0.7)'"

./helper_verifica_comandos.sh || exit 1

echo "Iniciando processo de autenticacao..."

USUARIO_TERRA=''
SENHA_TERRA=''

if [ -e cookies.txt ]; then
    echo "Existe um arquivo com cookies."
    if [ $((`date +%s`-`stat -c '%Y' cookies.txt`)) -lt 3600 ]; then
        echo "Testarei o arquivo para saber se ainda esta valido..."
        if wget -O index.html "$wget_comum" --load-cookies cookies.txt --save-cookies cookies.txt --keep-session-cookies 'http://fechado.terra.com.br/thegirl'; then
            if ! grep -i 'autentica.cgi' index.html > /dev/null 2>&1; then
                autenticou="1"
            fi
        fi
        rm -fv index.html
    else
        echo "Arquivo velho demais..."
    fi
fi

if [ "$autenticou" -ne 0 ]; then
    echo "Autenticacao realizada com sucesso."
    exit 0
else
    rm -fv cookies.txt
    echo -e 'Arquivo de cookies esta invalido ou nao existe.\nIniciando novo processo para obter um cookie valido...\n'
    echo -n "Digite o nome de usuario terra: "
    if [ "$USUARIO_TERRA" ]; then
        usuario="$USUARIO_TERRA"
        echo "$usuario"
        export USUARIO_TERRA=""
    else
        read usuario
    fi
    if ! [ "$usuario" ]; then
        echo "Abortado."
        exit 2
    fi
    echo -n "Digite a senha do usuario '$usuario': "
    if [ "$SENHA_TERRA" ]; then
        senha="$SENHA_TERRA"
        echo ' '
        export SENHA_TERRA=""
    else
        read -s senha
    fi
    if ! [ "$senha" ]; then
        echo "Abortado."
        exit 2
    fi
    echo -ne '\n'
    if wget -O index.html "$wget_comum" --save-cookies cookies.txt --keep-session-cookies --post-data "origem=GRL&pagina=grl/retorno.htm&url=http://www.terra.com.br/thegirl&email=${usuario}&senha=${senha}&enviar=" 'http://www.terra.com.br/autentica/autentica.cgi'; then
        if ! grep -ia 'autentica.cgi' index.html > /dev/null 2>&1; then
            autenticou="1"
        fi
    fi
    rm -fv index.html
    if [ "$autenticou" -ne 0 ]; then
        echo "Autenticacao realizada com sucesso."
        exit 0
    else
        echo "Processo de autenticacao falhou."
        rm -fv cookies.txt
        echo -n "Tentar novamente (S/N) ? "
        read resp
        if echo -e "yes\nsim" | egrep -i "^$resp" > /dev/null 2>&1; then
            "./$0"
            exit $?
        else
            echo "Abortado."
            exit 2
        fi
    fi
fi
