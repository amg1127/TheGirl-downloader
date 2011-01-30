# Em abril de 2008, o Terra reestruturou o TheGirl, colocando na URL das fotos o nome da modelo. Buaaaaa! :-(
# Mais trabalho para o programador... Algum jeito para determinar o nome da garota?

descobre_nome_garota () {
    # $1 => ano
    # $2 => mes
    # $3 => garota
    ano="$1"
    mes="$2"
    garota="$3"
    ano_m="`echo -n \"0000$ano\" | tail -c2`"
    mes_m="`echo -n \"0000$mes\" | tail -c2`"
    pastabase="ano20${ano_m}_mes${mes_m}_gar${garota}"
    mkdir -pv "$pastabase"
    arqnome="$pastabase/.nome-da-garota.txt"
    if [ -f "$arqnome" ]; then
        cat "$arqnome"
    else
        # Obter o 'index.htm' do ensaio
        garota_m=""
        [ "$garota" == "2" ] && garota_m="n"
        [ "$garota" == "3" ] && garota_m="verao"
        indexfile="$pastabase/.thegirl-garota-front-page.htm"
        endereco="http://www.terra.com.br/thegirl/${mes_m}${ano_m}${garota_m}/fotos-0101.htm"
        if wget -o /dev/stderr '--timeout=60' '--referer=http://www.terra.com.br/thegirl' '--user-agent=Mozilla/5.0 (X11; U; Linux i686; pt-BR; rv:1.7.12) Gecko/20051010 Firefox/1.0.4 (Ubuntu package 1.0.7)' '--continue' '--tries=3' -O "$indexfile" "$endereco"; then
            php -r "\$cont=\"\";while (! feof (STDIN)) { \$cont .= fread (STDIN, 1024); } if (preg_match (\"/<div\\\\s+id=[\\\"']foto[\\\"']\\\\s*>\\\\s*<img\\\\s+[^>]*src=[\\\"']fotos\\/([^0-9]*)-0101\\.jpg[\\\"'][^>]*>\\\\s*<\\\\/div>/i\", \$cont, \$m)) { echo (\$m[1]); }" < "$indexfile" > "$arqnome"
            if [ $? -ne 0 ]; then
                /bin/rm -f "$arqnome"
            elif [ -s "$arqnome" ]; then
                cat "$arqnome"
            else
                /bin/rm -f "$arqnome"
            fi
        else
            echo 'Erro: ensaio nao disponivel ou HTML da primeira foto nao foi encontrado!' > /dev/stderr
            exit 1
        fi
        /bin/rm -f "$indexfile"
    fi
}
