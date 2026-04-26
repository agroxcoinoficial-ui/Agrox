#!/data/data/com.termux/files/usr/bin/bash

VERDE='\033[0;32m'
AMARELO='\033[1;33m'
AZUL='\033[0;34m'
VERMELHO='\033[0;31m'
BRANCO='\033[1;37m'
SEMCOR='\033[0m'
NEGRITO='\033[1m'

DIR_AGROX="$HOME/monero"
DIR_BIN="$DIR_AGROX/build/bin"

mostrar_banner() {
    clear
    echo -e "${VERDE}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║         🌱 AGROX COIN 🌱           ║"
    echo "  ║  A Criptomoeda do Agronegócio      ║"
    echo "  ║  Nascida no RS - Brasil            ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${SEMCOR}"
}

verificar_instalacao() {
    if [ ! -f "$DIR_BIN/monerod" ]; then
        echo -e "${VERMELHO}❌ Agrox não está instalada!${SEMCOR}"
        echo "Deseja instalar agora? (s/n)"
        read -r opcao
        if [ "$opcao" = "s" ]; then
            instalar_agrox
        else
            exit 1
        fi
    fi
}
instalar_agrox() {
    echo -e "${AMARELO}📥 Instalando...${SEMCOR}"
    pkg update -y && pkg upgrade -y
    pkg install git cmake make clang boost openssl libsodium unbound -y
    if [ ! -d "$DIR_AGROX" ]; then
        git clone https://github.com/agroxcoinoficial-ui/Agrox.git "$DIR_AGROX"
    fi
    cd "$DIR_AGROX" && make build && cd build && cmake .. && make -j4
    echo -e "${VERDE}✅ Instalação concluída!${SEMCOR}"
    sleep 2
}

iniciar_daemon() {
    if pgrep -f "monerod" > /dev/null; then
        echo -e "${VERDE}✅ Daemon já está rodando!${SEMCOR}"
    else
        echo -e "${AMARELO}⛏️ Iniciando daemon...${SEMCOR}"
        cd "$DIR_BIN"
        ./monerod --rpc-bind-ip 127.0.0.1 --rpc-bind-port 28081 --fixed-difficulty 100 --offline --no-zmq --detach
        sleep 3
        echo -e "${VERDE}✅ Daemon iniciado!${SEMCOR}"
    fi
    sleep 1
}

parar_daemon() {
    pkill monerod
    echo -e "${VERDE}✅ Daemon parado!${SEMCOR}"
    sleep 1
}

criar_carteira() {
    echo "Nome da carteira:"
    read -r nome
    cd "$DIR_BIN"
    ./agrox-wallet-cli --generate-new-wallet "$nome"
    echo -e "${VERMELHO}⚠️ GUARDE AS 25 PALAVRAS! ⚠️${SEMCOR}"
    echo "Pressione ENTER..."
    read -r
}

abrir_carteira() {
    echo "Nome da carteira:"
    read -r nome
    if [ ! -f "$DIR_BIN/${nome}.keys" ]; then
        echo -e "${VERMELHO}❌ Carteira não encontrada!${SEMCOR}"
        sleep 2
        return
    fi
    cd "$DIR_BIN"
    ./agrox-wallet-cli --wallet-file "$nome"
}
ver_saldo() {
    echo "Nome da carteira:"
    read -r nome
    cd "$DIR_BIN"
    ./agrox-wallet-cli --wallet-file "$nome" --command "set_daemon 127.0.0.1:28081; refresh; balance; exit" 2>/dev/null | grep -A3 "Balance:"
    echo "Pressione ENTER..."
    read -r
}

minerar() {
    iniciar_daemon
    echo "Nome da carteira:"
    read -r nome
    echo "Threads (2 recomendado):"
    read -r threads
    cd "$DIR_BIN"
    ./agrox-wallet-cli --wallet-file "$nome" --command "set_daemon 127.0.0.1:28081; start_mining $threads; exit" 2>/dev/null
    echo -e "${VERDE}✅ Mineração iniciada!${SEMCOR}"
    sleep 2
}

transferir() {
    clear
    echo -e "${VERDE}💸 TRANSFERIR AGX${SEMCOR}"
    echo ""
    echo "Carteira de ORIGEM:"
    read -r origem
    echo "Valor a enviar:"
    read -r valor
    echo "Endereço de DESTINO:"
    read -r destino
    echo ""
    echo -e "Origem: $origem → Destino: $destino → Valor: $valor AGX"
    echo "Confirmar? (s/n)"
    read -r conf
    if [ "$conf" = "s" ]; then
        cd "$DIR_BIN"
        ./agrox-wallet-cli --wallet-file "$origem" --command "set_daemon 127.0.0.1:28081; transfer $destino $valor; save; exit" 2>/dev/null
        echo -e "${VERDE}✅ Transferência realizada!${SEMCOR}"
    fi
    echo "Pressione ENTER..."
    read -r
}
status_geral() {
    clear
    echo -e "${VERDE}📊 STATUS AGROX${SEMCOR}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
    if pgrep -f "monerod" > /dev/null; then
        echo -e "Daemon: ${VERDE}✅ Rodando${SEMCOR}"
    else
        echo -e "Daemon: ${VERMELHO}❌ Parado${SEMCOR}"
    fi
    altura=$(curl -s http://127.0.0.1:28081/get_info 2>/dev/null | grep -o '"height":[0-9]*' | cut -d: -f2)
    echo -e "Altura: ${AZUL}$altura blocos${SEMCOR}"
    echo ""
    echo "💰 Tokenomics: 50 AGX/bloco | Halving 5 anos | Supply 39M"
    echo "⛏️ Algoritmo: RandomX (CPU) | 🔒 Privacidade: RingCT"
    echo ""
    echo "Pressione ENTER..."
    read -r
}

while true; do
    verificar_instalacao
    mostrar_banner
    echo "  MENU PRINCIPAL"
    echo "  ─────────────────────────────"
    echo "  1 🚀 Iniciar Daemon"
    echo "  2 🛑 Parar Daemon"
    echo "  3 👛 Criar Nova Carteira"
    echo "  4 🔑 Abrir Carteira"
    echo "  5 💰 Ver Saldo"
    echo "  6 ⛏️  Iniciar Mineração"
    echo "  7 💸 Transferir AGX"
    echo "  8 📊 Status Geral"
    echo "  9 📥 Instalar/Reinstalar"
    echo "  0 🚪 Sair"
    echo "  ─────────────────────────────"
    echo -n "  Escolha: "
    read -r opcao
    case $opcao in
        1) iniciar_daemon ;;
        2) parar_daemon ;;
        3) criar_carteira ;;
        4) abrir_carteira ;;
        5) ver_saldo ;;
        6) minerar ;;
        7) transferir ;;
        8) status_geral ;;
        9) instalar_agrox ;;
        0) echo -e "${VERDE}🌱 Obrigado!${SEMCOR}"; exit 0 ;;
        *) echo -e "${VERMELHO}❌ Inválida!${SEMCOR}"; sleep 1 ;;
    esac
done
