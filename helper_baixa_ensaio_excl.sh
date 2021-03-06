#!/bin/bash

./helper_verifica_comandos.sh || exit 1
. ./helper_descobre_nome_garota.sh

echo 'Aviso: esse script nao verifica se um ensaio pode ser acessado sem precisar "digitar" o nome de usuario e a senha.'
echo 'Lembre-se tambem que esse script nao vai funcionar quando a senha for trocada.'

lohi1="g"
lohi2="HI"

if [ "$1" ]; then
    if echo -e "baixo\nlow" | egrep -i "^$1" > /dev/null 2>&1; then
        lohi1=""
        lohi2="LO"
    fi
fi

[ "$anoatras" ] || anoatras=4
export anoatras
comandorm="rm"

# Parametro 1: mensagem de erro
sai () {
    echo "Erro: $1."
    if [ "$2" ]; then
        exit $2
    else
        exit 1
    fi
}

# Parametro 1: ano do ensaio
# Parametro 2: mes do ensaio
# Parametro 3: a garota
# Parametro 4: o ensaio para pegar
# Parametro 5: a foto para pegar
# Parametro 6: o endereco que esta correto
# Retorna no stdout o endereco correto ou vazio, se nao der para montar
pega_endereco () {
    endereco_1="http://fechado.terra.com.br/thegirl/<MES><ANO><GAROTA>/fotos/<ENSAIO3>_<FOTO>${lohi1}.jpg"
    endereco_2="http://fechado.terra.com.br/thegirl/<MES><ANO><GAROTA>/fotos/<ENSAIO2>_<FOTO>${lohi1}.jpg"
    endereco=""
    [ "$6" == "1" ] && endereco="$endereco_1"
    [ "$6" == "2" ] && endereco="$endereco_2"
    if [ "$6" == 3 ]; then
        endereco="http://fechado.terra.com.br/thegirl/<MES><ANO><GAROTA>/fotos/`descobre_nome_garota \"$1\" \"$2\" \"$3\"`-<ENSAIO2><FOTO>${lohi1}.jpg"
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
    arquivo="ano20${ano}_mes${mes}_gar${3}_foto_excl_${lohi2}_${ensaio2}_${foto}.jpg"
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

if ! [ -e cookies.txt ]; then
    echo "A autenticacao nao foi feita. Executando './autentica_terra.sh'..."
    if ! ./autentica_terra.sh; then
        sai "A autenticacao nao foi feita. Saindo..." 2
    fi
fi

echo "Pronto para capturar o ensaio EXCLUSIVO $ensaio da garota $garota do mes $mes/$ano."

foto="1"
enderecocerto="1"
baixou1="0"
while true; do
    echo -e "Obtendo foto EXCLUSIVA $foto [usando modo de enderecamento $enderecocerto]...\n"
    arq_saida="`pega_nome_arquivo \"$ano\" \"$mes\" \"$garota\" \"$ensaio\" \"$foto\"`"
    if [ $? -ne 0 ]; then
        endereco="`pega_endereco \"$ano\" \"$mes\" \"$garota\" \"$ensaio\" \"$foto\" \"$enderecocerto\"`"
        if [ "$endereco" ]; then
            if wget '--timeout=60' '--referer=http://www.terra.com.br/thegirl' '--user-agent=Mozilla/5.0 (X11; U; Linux i686; pt-BR; rv:1.7.12) Gecko/20051010 Firefox/1.0.4 (Ubuntu package 1.0.7)' '--load-cookies' 'cookies.txt' '--save-cookies' 'cookies.txt' '--keep-session-cookies' '--continue' '--tries=0' -O "${arq_saida}" "$endereco"; then
                if [ "`file -b --mime-type \"${arq_saida}\"`" != "image/jpeg" ]; then
                    if grep -i 'autentica.cgi' "${arq_saida}" > /dev/null 2>&1; then
                        $comandorm -fv cookies.txt "${arq_saida}"
                        echo "Site do terra recusou os cookies presentes em 'cookies.txt'. Executando novamente './autentica_terra.sh'..."
                        if ! ./autentica_terra.sh; then
                            sai "Falha na autenticacao. Saindo..." 2
                        fi
                    fi
                    $comandorm -fv "${arq_saida}"
                    enderecocerto=$((enderecocerto+1))
                else
                    foto=$((foto+1))
                    baixou1="1"
                fi
            else
                $comandorm -fv "${arq_saida}"
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
