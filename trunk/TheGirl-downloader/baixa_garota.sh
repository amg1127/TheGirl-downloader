#!/bin/bash

./helper_verifica_comandos.sh || exit 1

[ "$anoatras" ] || anoatras=4
export anoatras

remove_pastas_vazias () {
    echo "Removendo pastas vazias..."
    rmdir * 2> /dev/null
}

# Parametro 1: mensagem de erro
sai () {
    echo "Erro: $1."
    remove_pastas_vazias
    exit 1
}

pastaexec="$0"
if  [ -h "$pastaexec" ]; then
    pastaexec="`readlink -f \"$pastaexec\"`"
fi
pastaexec="`dirname \"$pastaexec\"`"
cd "$pastaexec" || sai "nao consegui mudar diretorio de trabalho"

echo -n 'Ano (4 digitos) [padrao: ano atual]: '
read ano
[ "$ano" ] || ano="`date +%Y`"
[ "$ano" -le $((`date +%Y`+1)) ] || sai "ano digitado eh maior que o ano atual"
ano=$((ano+anoatras))
[ "$ano" -ge "`date +%Y`" ] || sai "ano digitado eh muito antigo"
ano=$((ano-anoatras))

echo -n 'Mes (de 1 a 13) [padrao: mes atual]: '
read mes
[ "$mes" ] || mes="`date +%m`"
[ "$mes" -lt 14 ] || sai "mes eh depois de dezembro"
[ "$mes" -gt 0 ] || sai "mes eh antes de janeiro"

echo -n 'Garota (digite 1, 2 ou 3) [padrao: 1]: '
read garota
[ "$garota" ] || garota="1"
[ "$garota" == "1" ] || [ "$garota" == "2" ] || [ "$garota" == "3" ] || sai "garota digitada eh invalido"

echo -n "Capturar ensaios exclusivos de resolucao menor (S/N)? [padrao: N] "
read captexclusivosLO
[ "$captexclusivosLO" ] || captexclusivosLO="N"

echo -n "Capturar ensaios exclusivos de resolucao maior (S/N)? [padrao: S] "
read captexclusivosHI
[ "$captexclusivosHI" ] || captexclusivosHI="S"

echo "Pronto para capturar a garota $garota do mes $mes/$ano."

echo "Vamos comecar pelos ensaios nao-exclusivos..."
ensaio=1
while echo -e "$ano\n$mes\n$garota\n$ensaio\n" | ./helper_baixa_ensaio_noexcl.sh; do
    ensaio=$((ensaio+1))
done
if [ "$ensaio" -eq 1 ]; then
    sai "processo filho nao baixou nenhum ensaio"
fi

ensaio_bak="$ensaio"
while (echo -e "yes\nsim" | egrep -i "^$captexclusivosLO" > /dev/null 2>&1) || (echo -e "yes\nsim" | egrep -i "^$captexclusivosHI" > /dev/null 2>&1); do
    if ./autentica_terra.sh; then
        echo "Baixando os ensaios exclusivos..."
        if echo -e "yes\nsim" | egrep -i "^$captexclusivosLO" > /dev/null 2>&1; then
            echo "Baixando os ensaios exclusivos de baixa resolucao..."
            ensaio="$ensaio_bak"
            while echo -e "$ano\n$mes\n$garota\n$ensaio\n" | ./helper_baixa_ensaio_excl.sh LOW; do
                ensaio=$((ensaio+1))
            done
            coderro="$?"
            if [ "$ensaio" -eq 1 ]; then
                if [ "$coderro" -eq 2 ]; then
                    continue
                else
                    echo "Erro: processo filho nao baixou nenhum ensaio. Continuando assim mesmo..."
                    captexclusivosLO="N"
                fi
            else
                captexclusivosLO="N"
            fi
        fi
        if echo -e "yes\nsim" | egrep -i "^$captexclusivosHI" > /dev/null 2>&1; then
            echo "Baixando os ensaios exclusivos de alta resolucao..."
            ensaio="$ensaio_bak"
            while echo -e "$ano\n$mes\n$garota\n$ensaio\n" | ./helper_baixa_ensaio_excl.sh HIGH; do
                ensaio=$((ensaio+1))
            done
            coderro="$?"
            if [ "$ensaio" -eq 1 ]; then
                if [ "$coderro" -eq 2 ]; then
                    continue
                else
                    echo "Erro: processo filho nao baixou nenhum ensaio. Continuando assim mesmo..."
                    captexclusivosHI="N"
                fi
            else
                captexclusivosHI="N"
            fi
        fi
    else
        echo "Sub-processo de autenticacao falhou."
        echo "Captura de ensaios exclusivos desativada."
        captexclusivosLO="N"
        captexclusivosHI="N"
    fi
done

echo "Baixando os posters, agora..."
echo -e "$ano\n$mes\n$garota\n" | ./helper_baixa_posters.sh

echo "Baixando os wallpapers, agora..."
echo -e "$ano\n$mes\n$garota\n" | ./helper_baixa_wallpapers.sh

# echo "Recriando pastas de SYMLINKS..."
# ./mksymlinks.sh

remove_pastas_vazias
echo -e "\n **** Concluido. ****"
exit 0
