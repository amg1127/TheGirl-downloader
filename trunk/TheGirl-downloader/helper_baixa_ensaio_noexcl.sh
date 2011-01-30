#!/bin/bash

[ "$anoatras" ] || anoatras=4
export anoatras

./helper_verifica_comandos.sh || exit 1
. ./helper_descobre_nome_garota.sh

# Parametro 1: mensagem de erro
sai () {
    echo "Erro: $1."
    exit 1
}

# Parametro 1: ano do ensaio
# Parametro 2: mes do ensaio
# Parametro 3: a garota
# Parametro 4: o ensaio para pegar
# Parametro 5: a foto para pegar
# Parametro 6: o endereco que esta correto
# Retorna no stdout o endereco correto ou vazio, se nao der para montar
pega_endereco () {
    endereco_1="http://img.terra.com.br/thegirl/<MES><ANO><GAROTA>/fotos/<ENSAIO3>_<FOTO>.jpg"
    endereco_2="http://www.terra.com.br/thegirl/<MES><ANO><GAROTA>/fotos2/<ENSAIO2>_<FOTO>.jpg"
    endereco_3="http://www.terra.com.br/thegirl/<MES><ANO><GAROTA>/fotos/<ENSAIO2>_<FOTO>.jpg"
    endereco=""
    [ "$6" == "1" ] && endereco="$endereco_1"
    [ "$6" == "2" ] && endereco="$endereco_2"
    [ "$6" == "3" ] && endereco="$endereco_3"
    if [ "$6" == "4" ]; then
        # http://www.terra.com.br/thegirl/0408/fotos/andressa-barros-0101.jpg
        endereco="http://www.terra.com.br/thegirl/<MES><ANO><GAROTA>/fotos/`descobre_nome_garota \"$1\" \"$2\" \"$3\"`-<ENSAIO2><FOTO>.jpg"
    fi
    [ "$endereco" ] || return 1
    ano="`echo -n \"0000$1\" | tail -c2`"
    mes="`echo -n \"0000$2\" | tail -c2`"
    garota=""
    [ "$3" == "2" ] && garota="n"
    [ "$3" == "3" ] && garota="verao"
    ensaio2="`echo -n \"0000$4\" | tail -c2`"
    ensaio3="`echo -n \"0000$4\" | tail -c3`"
    foto="`echo -n \"0000$5\" | tail -c2`"
    endereco="`echo \"$endereco\" | sed \"s/<ANO>/$ano/g\" | sed \"s/<MES>/$mes/g\" | sed \"s/<GAROTA>/$garota/g\" | sed \"s/<ENSAIO3>/$ensaio3/g\" | sed \"s/<ENSAIO2>/$ensaio2/g\" | sed \"s/<FOTO>/$foto/g\"`"
    echo -n "$endereco"
    return 0
}

# Parametro 1: ano do ensaio
# Parametro 2: mes do ensaio
# Parametro 3: a garota
# Parametro 4: o ensaio para pegar
# Parametro 5: a foto para pegar
# Retorna no stdout o caminho completo do arquivo destino
# Retorna sucesso se o arquivo ja existe
pega_nome_arquivo () {
    ano="`echo -n \"0000$1\" | tail -c2`"
    mes="`echo -n \"0000$2\" | tail -c2`"
    garota=""
    [ "$3" == "2" ] && garota="n"
    [ "$3" == "3" ] && garota="verao"
    ensaio2="`echo -n \"0000$4\" | tail -c2`"
    ensaio3="`echo -n \"0000$4\" | tail -c3`"
    foto="`echo -n \"0000$5\" | tail -c2`"
    pasta="ano20${ano}_mes${mes}_gar${3}"
    arquivo="ano20${ano}_mes${mes}_gar${3}_foto_${ensaio2}_${foto}.jpg"
    fname="${pasta}/${arquivo}"
    echo -n "$fname"
    mkdir -pv "$pasta" || sai "erro criando pasta para baixar as fotos"
    [ -f "$fname" ]
    return $?
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
[ "$ano" -le $((1+`date +%Y`)) ] || sai "ano digitado eh maior que o ano atual"
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

echo -n 'Ensaio para obter [padrao: 1]: '
read ensaio
[ "$ensaio" ] || ensaio="1"
[ "$ensaio" -gt 0 ] || sai "ensaio digitado eh invalido"

echo "Pronto para capturar o ensaio $ensaio da garota $garota do mes $mes/$ano."

foto="1"
enderecocerto="1"
baixou1="0"
while true; do
    echo -e "Obtendo foto $foto [usando modo de enderecamento $enderecocerto]...\n"
    arq_saida="`pega_nome_arquivo \"$ano\" \"$mes\" \"$garota\" \"$ensaio\" \"$foto\"`"
    if [ $? -ne 0 ]; then
        endereco="`pega_endereco \"$ano\" \"$mes\" \"$garota\" \"$ensaio\" \"$foto\" \"$enderecocerto\"`"
        if [ "$endereco" ]; then
            if wget '--timeout=60' '--referer=http://www.terra.com.br/thegirl' '--user-agent=Mozilla/5.0 (X11; U; Linux i686; pt-BR; rv:1.7.12) Gecko/20051010 Firefox/1.0.4 (Ubuntu package 1.0.7)' '--continue' '--tries=0' -O "${arq_saida}" "$endereco"; then
                if [ "`file -b --mime-type \"${arq_saida}\"`" != "image/jpeg" ]; then
                    rm -fv "${arq_saida}"
                    enderecocerto=$((enderecocerto+1))
                else
                    foto=$((foto+1))
                    baixou1="1"
                fi
            else
                rm -fv "${arq_saida}"
                enderecocerto=$((enderecocerto+1))
            fi
        else
            if [ "$baixou1" -ne 0 ]; then
                foto=$((foto-1))
                echo -e "\n$foto fotos foram baixadas. Parece que terminou..."
                break;
            else
                sai "nenhum endereco disponivel. Abortando.."
            fi
        fi
    else
        echo -e "Pulando foto $foto, porque a foto ja existe...\n"
        foto=$((foto+1))
        baixou1="1"
    fi
done

exit 0
