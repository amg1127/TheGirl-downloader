#!/bin/bash

linka () {
    quant=$((`ls --color=no | wc --lines`+1))
    # ln -sv "$1" "`echo -n \"0000000${quant}\" | tail -c6`.jpg"
    ln -sv "$1"
}

lookforphotos () {
    y="$1"
    mes="$2"
    garota="$3"
    ensaio=1
    fm1="../ano${y}_mes${mes}_gar${garota}/ano${y}_mes${mes}_gar${garota}_foto"
    fm2="../ano${y}_mes${mes}_gar${garota}/ano${y}_mes${mes}_gar${garota}_foto_excl_LO"
    fm3="../ano${y}_mes${mes}_gar${garota}/ano${y}_mes${mes}_gar${garota}_foto_excl_HI"
    while true; do
        ens="`echo -n \"000$ensaio\" | tail -c2`"
        if ( ( [ -e "${fm1}_${ens}_01.jpg" ] ) || \
             ( [ -e "${fm2}_${ens}_01.jpg" ] ) || \
             ( [ -e "${fm3}_${ens}_01.jpg" ] ) ); then
            ensaio=$((ensaio+1))
        else
            break
        fi
    done
    ensaio=$((ensaio-1))
    while [ $ensaio -gt 0 ]; do
        ens="`echo -n \"000$ensaio\" | tail -c2`"
        foto=1
        while true; do
            fo="`echo -n \"000$foto\" | tail -c2`"
            if ( [ "$link_excl_hi" == 1 ] && [ -e "${fm3}_${ens}_${fo}.jpg" ] ); then
                linka "${fm3}_${ens}_${fo}.jpg"
                foto=$((foto+1))
            else
                break
            fi
        done
        foto=1
        while true; do
            fo="`echo -n \"000$foto\" | tail -c2`"
            if ( [ "$link_excl_lo" == 1 ] && [ -e "${fm2}_${ens}_${fo}.jpg" ] ); then
                linka "${fm2}_${ens}_${fo}.jpg"
                foto=$((foto+1))
            else
                break
            fi
        done
        foto=1
        while true; do
            fo="`echo -n \"000$foto\" | tail -c2`"
            if ( [ "$link_noexcl" == 1 ] && [ -e "${fm1}_${ens}_${fo}.jpg" ] ); then
                linka "${fm1}_${ens}_${fo}.jpg"
                foto=$((foto+1))
            else
                break
            fi
        done
        ensaio=$((ensaio-1))
    done
}

lookforyear () {
    conta=0
    y="$1"
    for mes in `seq -f %02g 12 -1 1`; do
        for garota in `seq 9 -1 1`; do
            if [ -e "../ano${y}_mes${mes}_gar${garota}" ]; then
                conta=$((conta+1))
                lookforphotos $y $mes $garota
            fi
        done
    done
    if [ $conta -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

criatodas () {
    # Pasta para onde os links serao guardados
    export admindir="$1"
    # Ativar fotos nao-exclusivas?
    export link_noexcl="$2"
    # Ativar fotos exclusivas de baixa resolucao?
    export link_excl_lo="$3"
    # Ativar fotos exclusivas de alta resolucao?
    export link_excl_hi="$4"

    olddir="`pwd`"
    mkdir -pv "$admindir"
    cd "$admindir"
    rm -fv *.jpg
    ano="`date +%Y`"
    while lookforyear $ano; do
        ano=$((ano-1))
    done
    cd "$olddir"
}

espera () {
    while [ "$1" ]; do
        while [ -e "/proc/$1" ]; do
            sleep 1
        done
        shift
    done
}

criatodas SYMLINKS_ALL 1 0 1 & pid1=$!
criatodas SYMLINKS_EXCL 0 0 1 & pid2=$!
espera $pid1 $pid2
