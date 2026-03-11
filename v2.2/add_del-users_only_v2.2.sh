#!/bin/bash

AMNEZIAWG_DIR="/etc/amnezia/amneziawg"

RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Safely quote a value for inclusion in a sourced params file
# Escapes single quotes and wraps in single quotes to prevent shell injection
function safeQuoteParam() {
    local VALUE="$1"
    # Replace single quotes with '\'' (end quote, escaped quote, start quote)
    local ESCAPED="${VALUE//\'/\'\\\'\'}"
    echo "'${ESCAPED}'"
}

function getHomeDirForClient() {
    local CLIENT_NAME=$1
    if [ -z "${CLIENT_NAME}" ]; then
        echo "Error: getHomeDirForClient() requires a client name as argument"
        exit 1
    fi

    if [ -e "/home/${CLIENT_NAME}" ]; then
        HOME_DIR="/home/${CLIENT_NAME}"
    elif [ "${SUDO_USER}" ]; then
        if [ "${SUDO_USER}" == "root" ]; then
            HOME_DIR="/root"
        else
            HOME_DIR="/home/${SUDO_USER}"
        fi
    else
        HOME_DIR="/root"
    fi
    echo "$HOME_DIR"
}

function loadParams() {
    source "${AMNEZIAWG_DIR}/params"
    SERVER_AWG_CONF="${AMNEZIAWG_DIR}/${SERVER_AWG_NIC}.conf"
    
    # Initialize I parameters if they don't exist
    if [[ -z "${SERVER_AWG_I1}" ]]; then
        DEFAULT_I1="<b 0x084481800001000300000000077469636b65747306776964676574096b696e6f706f69736b0272750000010001c00c0005000100000039001806776964676574077469636b6574730679616e646578c025c0390005000100000039002b1765787465726e616c2d7469636b6574732d776964676574066166697368610679616e646578036e657400c05d000100010000001c000457fafe25>"
        SERVER_AWG_I1="${DEFAULT_I1}"
    fi
    
    # I2-I5 remain empty if not set
    SERVER_AWG_I2="${SERVER_AWG_I2:-}"
    SERVER_AWG_I3="${SERVER_AWG_I3:-}"
    SERVER_AWG_I4="${SERVER_AWG_I4:-}"
    SERVER_AWG_I5="${SERVER_AWG_I5:-}"
    
    # Check if I parameters exist in server config and add them if missing
    local CONF_UPDATED=0
    
    if ! grep -q "^I1 = " "${SERVER_AWG_CONF}" 2>/dev/null; then
        echo "I1 = ${SERVER_AWG_I1}" >> "${SERVER_AWG_CONF}"
        CONF_UPDATED=1
    fi
    
    if [[ -n "${SERVER_AWG_I2}" && "${SERVER_AWG_I2}" != "''" ]] && ! grep -q "^I2 = " "${SERVER_AWG_CONF}" 2>/dev/null; then
        echo "I2 = ${SERVER_AWG_I2}" >> "${SERVER_AWG_CONF}"
        CONF_UPDATED=1
    fi
    
    if [[ -n "${SERVER_AWG_I3}" && "${SERVER_AWG_I3}" != "''" ]] && ! grep -q "^I3 = " "${SERVER_AWG_CONF}" 2>/dev/null; then
        echo "I3 = ${SERVER_AWG_I3}" >> "${SERVER_AWG_CONF}"
        CONF_UPDATED=1
    fi
    
    if [[ -n "${SERVER_AWG_I4}" && "${SERVER_AWG_I4}" != "''" ]] && ! grep -q "^I4 = " "${SERVER_AWG_CONF}" 2>/dev/null; then
        echo "I4 = ${SERVER_AWG_I4}" >> "${SERVER_AWG_CONF}"
        CONF_UPDATED=1
    fi
    
    if [[ -n "${SERVER_AWG_I5}" && "${SERVER_AWG_I5}" != "''" ]] && ! grep -q "^I5 = " "${SERVER_AWG_CONF}" 2>/dev/null; then
        echo "I5 = ${SERVER_AWG_I5}" >> "${SERVER_AWG_CONF}"
        CONF_UPDATED=1
    fi
    
    if [[ ${CONF_UPDATED} == 1 ]]; then
        echo -e "${GREEN}Added missing I parameters to server configuration.${NC}"
    fi
}

# Function to update I parameters in server config and all client configs
function updateAllIConfigs() {
    local UPDATED=0
    
    echo -e "${GREEN}Updating I parameters in server configuration...${NC}"
    
    # Update I1 in server config
    if grep -q "^I1 = " "${SERVER_AWG_CONF}"; then
        sed -i "s|^I1 = .*|I1 = ${SERVER_AWG_I1}|" "${SERVER_AWG_CONF}"
    else
        # Insert I1 after H4 or at the end of Interface section
        if grep -q "^H4 = " "${SERVER_AWG_CONF}"; then
            sed -i "/^H4 = .*/a I1 = ${SERVER_AWG_I1}" "${SERVER_AWG_CONF}"
        else
            echo "I1 = ${SERVER_AWG_I1}" >> "${SERVER_AWG_CONF}"
        fi
    fi
    
    # Update I2 in server config
    if [[ -n "${SERVER_AWG_I2}" && "${SERVER_AWG_I2}" != "''" ]]; then
        if grep -q "^I2 = " "${SERVER_AWG_CONF}"; then
            sed -i "s|^I2 = .*|I2 = ${SERVER_AWG_I2}|" "${SERVER_AWG_CONF}"
        else
            sed -i "/^I1 = .*/a I2 = ${SERVER_AWG_I2}" "${SERVER_AWG_CONF}"
        fi
    else
        # Remove I2 if it exists (when set to empty)
        sed -i "/^I2 = /d" "${SERVER_AWG_CONF}"
    fi
    
    # Update I3 in server config
    if [[ -n "${SERVER_AWG_I3}" && "${SERVER_AWG_I3}" != "''" ]]; then
        if grep -q "^I3 = " "${SERVER_AWG_CONF}"; then
            sed -i "s|^I3 = .*|I3 = ${SERVER_AWG_I3}|" "${SERVER_AWG_CONF}"
        else
            sed -i "/^I2 = .*/a I3 = ${SERVER_AWG_I3}" "${SERVER_AWG_CONF}"
        fi
    else
        sed -i "/^I3 = /d" "${SERVER_AWG_CONF}"
    fi
    
    # Update I4 in server config
    if [[ -n "${SERVER_AWG_I4}" && "${SERVER_AWG_I4}" != "''" ]]; then
        if grep -q "^I4 = " "${SERVER_AWG_CONF}"; then
            sed -i "s|^I4 = .*|I4 = ${SERVER_AWG_I4}|" "${SERVER_AWG_CONF}"
        else
            sed -i "/^I3 = .*/a I4 = ${SERVER_AWG_I4}" "${SERVER_AWG_CONF}"
        fi
    else
        sed -i "/^I4 = /d" "${SERVER_AWG_CONF}"
    fi
    
    # Update I5 in server config
    if [[ -n "${SERVER_AWG_I5}" && "${SERVER_AWG_I5}" != "''" ]]; then
        if grep -q "^I5 = " "${SERVER_AWG_CONF}"; then
            sed -i "s|^I5 = .*|I5 = ${SERVER_AWG_I5}|" "${SERVER_AWG_CONF}"
        else
            sed -i "/^I4 = .*/a I5 = ${SERVER_AWG_I5}" "${SERVER_AWG_CONF}"
        fi
    else
        sed -i "/^I5 = /d" "${SERVER_AWG_CONF}"
    fi
    
    echo -e "${GREEN}Server configuration updated.${NC}"
    
    # Update all client configurations
    echo -e "${GREEN}Updating I parameters in all client configurations...${NC}"
    
    # Get list of all clients
    local CLIENTS=$(grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3)
    local CLIENT_COUNT=0
    
    for CLIENT in $CLIENTS; do
        HOME_DIR=$(getHomeDirForClient "${CLIENT}")
        CLIENT_CONF="${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT}.conf"
        
        if [[ -f "${CLIENT_CONF}" ]]; then
            # Update I1 in client config
            if grep -q "^I1 = " "${CLIENT_CONF}"; then
                sed -i "s|^I1 = .*|I1 = ${SERVER_AWG_I1}|" "${CLIENT_CONF}"
            else
                # Insert I1 after H4 or at the end of Interface section
                if grep -q "^H4 = " "${CLIENT_CONF}"; then
                    sed -i "/^H4 = .*/a I1 = ${SERVER_AWG_I1}" "${CLIENT_CONF}"
                else
                    # Find the Interface section end (before [Peer])
                    sed -i "/^\[Peer\]/i I1 = ${SERVER_AWG_I1}" "${CLIENT_CONF}"
                fi
            fi
            
            # Update I2 in client config
            if [[ -n "${SERVER_AWG_I2}" && "${SERVER_AWG_I2}" != "''" ]]; then
                if grep -q "^I2 = " "${CLIENT_CONF}"; then
                    sed -i "s|^I2 = .*|I2 = ${SERVER_AWG_I2}|" "${CLIENT_CONF}"
                else
                    sed -i "/^I1 = .*/a I2 = ${SERVER_AWG_I2}" "${CLIENT_CONF}"
                fi
            else
                sed -i "/^I2 = /d" "${CLIENT_CONF}"
            fi
            
            # Update I3 in client config
            if [[ -n "${SERVER_AWG_I3}" && "${SERVER_AWG_I3}" != "''" ]]; then
                if grep -q "^I3 = " "${CLIENT_CONF}"; then
                    sed -i "s|^I3 = .*|I3 = ${SERVER_AWG_I3}|" "${CLIENT_CONF}"
                else
                    sed -i "/^I2 = .*/a I3 = ${SERVER_AWG_I3}" "${CLIENT_CONF}"
                fi
            else
                sed -i "/^I3 = /d" "${CLIENT_CONF}"
            fi
            
            # Update I4 in client config
            if [[ -n "${SERVER_AWG_I4}" && "${SERVER_AWG_I4}" != "''" ]]; then
                if grep -q "^I4 = " "${CLIENT_CONF}"; then
                    sed -i "s|^I4 = .*|I4 = ${SERVER_AWG_I4}|" "${CLIENT_CONF}"
                else
                    sed -i "/^I3 = .*/a I4 = ${SERVER_AWG_I4}" "${CLIENT_CONF}"
                fi
            else
                sed -i "/^I4 = /d" "${CLIENT_CONF}"
            fi
            
            # Update I5 in client config
            if [[ -n "${SERVER_AWG_I5}" && "${SERVER_AWG_I5}" != "''" ]]; then
                if grep -q "^I5 = " "${CLIENT_CONF}"; then
                    sed -i "s|^I5 = .*|I5 = ${SERVER_AWG_I5}|" "${CLIENT_CONF}"
                else
                    sed -i "/^I4 = .*/a I5 = ${SERVER_AWG_I5}" "${CLIENT_CONF}"
                fi
            else
                sed -i "/^I5 = /d" "${CLIENT_CONF}"
            fi
            
            CLIENT_COUNT=$((CLIENT_COUNT + 1))
            echo -e "${GREEN}  Updated: ${CLIENT_CONF}${NC}"
        fi
    done
    
    # Save I parameters to params file
    saveIParams
    
    # Reload AmneziaWG configuration - ИСПОЛЬЗУЕМ RESTART ВМЕСТО SYNCONF
    if systemctl is-active --quiet "awg-quick@${SERVER_AWG_NIC}"; then
        echo -e "${GREEN}Перезапуск сервиса для применения изменений I-параметров...${NC}"
        systemctl restart "awg-quick@${SERVER_AWG_NIC}"
        echo -e "${GREEN}AmneziaWG сервис перезапущен.${NC}"
    fi
    
    echo -e "${GREEN}I parameters updated in server config and ${CLIENT_COUNT} client config(s).${NC}"
    echo -e "${ORANGE}IMPORTANT: All connected clients must reconnect to apply the new I parameters.${NC}"
}

# Function to change I parameters - ИСПРАВЛЕНО
function changeIParams() {
    while true; do
        echo ""
        echo "Current I parameter values:"
        echo "   1) I1 = ${SERVER_AWG_I1}"
        echo "   2) I2 = ${SERVER_AWG_I2:-<not set>}"
        echo "   3) I3 = ${SERVER_AWG_I3:-<not set>}"
        echo "   4) I4 = ${SERVER_AWG_I4:-<not set>}"
        echo "   5) I5 = ${SERVER_AWG_I5:-<not set>}"
        echo "   6) Back to main menu"
        echo ""
        
        local CHOICE=""
        local PROMPT="Select parameter to change [1-6]: "
        
        # Выводим приглашение
        echo -n "$PROMPT"
        
        while true; do
            # Читаем один символ без ожидания Enter
            read -s -n 1 KEY
            
            # Если нажат Enter
            if [[ -z "$KEY" ]]; then
                # Возвращаем курсор в начало строки и перезаписываем приглашение
                echo -en "\r\033[K$PROMPT"
                continue
            fi
            
            # Если введена цифра
            if [[ "$KEY" =~ [1-6] ]]; then
                CHOICE="$KEY"
                echo "$KEY"  # Показываем введенную цифру
                echo ""  # Переходим на новую строку
                break
            else
                # Если не цифра от 1 до 6
                echo -e "\r\033[K${PROMPT}Please enter a number between 1 and 6.\n$PROMPT"
            fi
        done
        
        case "${CHOICE}" in
            1)
                echo ""
                echo "Current I1 value: ${SERVER_AWG_I1}"
                local NEW_VALUE=""
                local I1_PROMPT="Enter new I1 value (or press Enter to keep current): "
                
                echo -n "$I1_PROMPT"
                # Читаем строку полностью (для длинных I параметров)
                read NEW_VALUE
                
                if [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I1="${NEW_VALUE}"
                    echo -e "${GREEN}I1 updated successfully${NC}"
                    updateAllIConfigs
                else
                    echo -e "${ORANGE}I1 unchanged${NC}"
                fi
                ;;
            2)
                echo ""
                echo "Current I2 value: ${SERVER_AWG_I2:-<not set>}"
                local NEW_VALUE=""
                local I2_PROMPT="Enter new I2 value (or press Enter to keep current, 'none' to remove): "
                
                echo -n "$I2_PROMPT"
                read NEW_VALUE
                
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I2=""
                    echo -e "${GREEN}I2 removed${NC}"
                    updateAllIConfigs
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I2="${NEW_VALUE}"
                    echo -e "${GREEN}I2 updated successfully${NC}"
                    updateAllIConfigs
                else
                    echo -e "${ORANGE}I2 unchanged${NC}"
                fi
                ;;
            3)
                echo ""
                echo "Current I3 value: ${SERVER_AWG_I3:-<not set>}"
                local NEW_VALUE=""
                local I3_PROMPT="Enter new I3 value (or press Enter to keep current, 'none' to remove): "
                
                echo -n "$I3_PROMPT"
                read NEW_VALUE
                
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I3=""
                    echo -e "${GREEN}I3 removed${NC}"
                    updateAllIConfigs
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I3="${NEW_VALUE}"
                    echo -e "${GREEN}I3 updated successfully${NC}"
                    updateAllIConfigs
                else
                    echo -e "${ORANGE}I3 unchanged${NC}"
                fi
                ;;
            4)
                echo ""
                echo "Current I4 value: ${SERVER_AWG_I4:-<not set>}"
                local NEW_VALUE=""
                local I4_PROMPT="Enter new I4 value (or press Enter to keep current, 'none' to remove): "
                
                echo -n "$I4_PROMPT"
                read NEW_VALUE
                
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I4=""
                    echo -e "${GREEN}I4 removed${NC}"
                    updateAllIConfigs
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I4="${NEW_VALUE}"
                    echo -e "${GREEN}I4 updated successfully${NC}"
                    updateAllIConfigs
                else
                    echo -e "${ORANGE}I4 unchanged${NC}"
                fi
                ;;
            5)
                echo ""
                echo "Current I5 value: ${SERVER_AWG_I5:-<not set>}"
                local NEW_VALUE=""
                local I5_PROMPT="Enter new I5 value (or press Enter to keep current, 'none' to remove): "
                
                echo -n "$I5_PROMPT"
                read NEW_VALUE
                
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I5=""
                    echo -e "${GREEN}I5 removed${NC}"
                    updateAllIConfigs
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I5="${NEW_VALUE}"
                    echo -e "${GREEN}I5 updated successfully${NC}"
                    updateAllIConfigs
                else
                    echo -e "${ORANGE}I5 unchanged${NC}"
                fi
                ;;
            6)
                echo ""
                return
                ;;
        esac
        
        # Small pause to let user see the message before menu refreshes
        if [[ ${CHOICE} -ne 6 ]]; then
            echo ""
            # Исправлено для "Press Enter to continue"
            local CONTINUE_PROMPT="Press Enter to continue..."
            echo -n "$CONTINUE_PROMPT"
            read -s DUMMY
            echo ""  # Переходим на новую строку после нажатия Enter
        fi
    done
}

# Function to save I parameters to params file
function saveIParams() {
    local PARAMS_FILE="${AMNEZIAWG_DIR}/params"
    local TEMP_FILE="${AMNEZIAWG_DIR}/params.tmp.$$"
    
    # Create a backup
    cp "${PARAMS_FILE}" "${PARAMS_FILE}.bak"
    
    # Update the params file with new I values
    while IFS= read -r line; do
        if [[ "${line}" =~ ^SERVER_AWG_I1= ]]; then
            echo "SERVER_AWG_I1=$(safeQuoteParam "${SERVER_AWG_I1}")"
        elif [[ "${line}" =~ ^SERVER_AWG_I2= ]]; then
            echo "SERVER_AWG_I2=$(safeQuoteParam "${SERVER_AWG_I2}")"
        elif [[ "${line}" =~ ^SERVER_AWG_I3= ]]; then
            echo "SERVER_AWG_I3=$(safeQuoteParam "${SERVER_AWG_I3}")"
        elif [[ "${line}" =~ ^SERVER_AWG_I4= ]]; then
            echo "SERVER_AWG_I4=$(safeQuoteParam "${SERVER_AWG_I4}")"
        elif [[ "${line}" =~ ^SERVER_AWG_I5= ]]; then
            echo "SERVER_AWG_I5=$(safeQuoteParam "${SERVER_AWG_I5}")"
        else
            echo "${line}"
        fi
    done < "${PARAMS_FILE}" > "${TEMP_FILE}"
    
    # Check if I parameters are missing in the file and add them
    if ! grep -q "^SERVER_AWG_I1=" "${TEMP_FILE}"; then
        echo "SERVER_AWG_I1=$(safeQuoteParam "${SERVER_AWG_I1}")" >> "${TEMP_FILE}"
    fi
    if ! grep -q "^SERVER_AWG_I2=" "${TEMP_FILE}" && [[ -n "${SERVER_AWG_I2}" ]]; then
        echo "SERVER_AWG_I2=$(safeQuoteParam "${SERVER_AWG_I2}")" >> "${TEMP_FILE}"
    fi
    if ! grep -q "^SERVER_AWG_I3=" "${TEMP_FILE}" && [[ -n "${SERVER_AWG_I3}" ]]; then
        echo "SERVER_AWG_I3=$(safeQuoteParam "${SERVER_AWG_I3}")" >> "${TEMP_FILE}"
    fi
    if ! grep -q "^SERVER_AWG_I4=" "${TEMP_FILE}" && [[ -n "${SERVER_AWG_I4}" ]]; then
        echo "SERVER_AWG_I4=$(safeQuoteParam "${SERVER_AWG_I4}")" >> "${TEMP_FILE}"
    fi
    if ! grep -q "^SERVER_AWG_I5=" "${TEMP_FILE}" && [[ -n "${SERVER_AWG_I5}" ]]; then
        echo "SERVER_AWG_I5=$(safeQuoteParam "${SERVER_AWG_I5}")" >> "${TEMP_FILE}"
    fi
    
    mv "${TEMP_FILE}" "${PARAMS_FILE}"
    rm -f "${PARAMS_FILE}.bak"
    
    echo -e "${GREEN}I parameters saved successfully${NC}"
}

function newClient() {
    # IPv6 → в квадратные скобки
    if [[ ${SERVER_PUB_IP} =~ .*:.* ]]; then
        if [[ ${SERVER_PUB_IP} != *"["* ]] || [[ ${SERVER_PUB_IP} != *"]"* ]]; then
            SERVER_PUB_IP="[${SERVER_PUB_IP}]"
        fi
    fi
    ENDPOINT="${SERVER_PUB_IP}:${SERVER_PORT}"

    echo ""
    echo "Client configuration"
    echo ""

    local CLIENT_NAME=""
    local CLIENT_EXISTS=""
    
    # Исправлено для ввода имени клиента
    local NAME_PROMPT="Client name: "
    
    until [[ ${CLIENT_NAME} =~ ^[a-zA-Z0-9_-]+$ && ${CLIENT_EXISTS} == '0' && ${#CLIENT_NAME} -lt 16 ]]; do
        echo -n "$NAME_PROMPT"
        read CLIENT_NAME
        if [[ -z "${CLIENT_NAME}" ]]; then
            echo "Client name cannot be empty."
            continue
        fi
        CLIENT_EXISTS=$(grep -c -E "^### Client ${CLIENT_NAME}\$" "${SERVER_AWG_CONF}")
        if [[ ${CLIENT_EXISTS} != 0 ]]; then
            echo "A client with this name already exists, please choose another."
        fi
    done

    local DOT_IP=""
    local DOT_EXISTS=""
    for DOT_IP in {2..254}; do
        DOT_EXISTS=$(grep -c "${SERVER_AWG_IPV4::-1}${DOT_IP}" "${SERVER_AWG_CONF}")
        if [[ ${DOT_EXISTS} == '0' ]]; then
            break
        fi
    done

    CLIENT_AWG_IPV4="$(echo "$SERVER_AWG_IPV4" | awk -F '.' '{print $1"."$2"."$3}').${DOT_IP}"
    CLIENT_AWG_IPV6="$(echo "$SERVER_AWG_IPV6" | awk -F '::' '{print $1}')::${DOT_IP}"

    CLIENT_PRIV_KEY=$(awg genkey)
    CLIENT_PUB_KEY=$(echo "${CLIENT_PRIV_KEY}" | awg pubkey)
    CLIENT_PRE_SHARED_KEY=$(awg genpsk)

    HOME_DIR=$(getHomeDirForClient "${CLIENT_NAME}")

    # Create client file with base configuration
    cat >"${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = ${CLIENT_AWG_IPV4}/32,${CLIENT_AWG_IPV6}/128
DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}
Jc = ${SERVER_AWG_JC}
Jmin = ${SERVER_AWG_JMIN}
Jmax = ${SERVER_AWG_JMAX}
S1 = ${SERVER_AWG_S1}
S2 = ${SERVER_AWG_S2}
S3 = ${SERVER_AWG_S3}
S4 = ${SERVER_AWG_S4}
H1 = ${SERVER_AWG_H1}
H2 = ${SERVER_AWG_H2}
H3 = ${SERVER_AWG_H3}
H4 = ${SERVER_AWG_H4}
EOF

    # Add I parameters (only if they have values)
    {
        if [[ -n "${SERVER_AWG_I1}" && "${SERVER_AWG_I1}" != "''" ]]; then
            echo "I1 = ${SERVER_AWG_I1}"
        fi
        if [[ -n "${SERVER_AWG_I2}" && "${SERVER_AWG_I2}" != "''" ]]; then
            echo "I2 = ${SERVER_AWG_I2}"
        fi
        if [[ -n "${SERVER_AWG_I3}" && "${SERVER_AWG_I3}" != "''" ]]; then
            echo "I3 = ${SERVER_AWG_I3}"
        fi
        if [[ -n "${SERVER_AWG_I4}" && "${SERVER_AWG_I4}" != "''" ]]; then
            echo "I4 = ${SERVER_AWG_I4}"
        fi
        if [[ -n "${SERVER_AWG_I5}" && "${SERVER_AWG_I5}" != "''" ]]; then
            echo "I5 = ${SERVER_AWG_I5}"
        fi
    } >>"${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"

    # Add Peer section
    cat >>"${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf" <<EOF

[Peer]
PublicKey = ${SERVER_PUB_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
Endpoint = ${ENDPOINT}
AllowedIPs = ${ALLOWED_IPS}
EOF

    if [[ ${KEEPALIVE} -ne 0 ]]; then
        echo "PersistentKeepalive = ${KEEPALIVE}" >>"${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
    fi

    echo -e "\n### Client ${CLIENT_NAME}
[Peer]
PublicKey = ${CLIENT_PUB_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = ${CLIENT_AWG_IPV4}/32,${CLIENT_AWG_IPV6}/128" >>"${SERVER_AWG_CONF}"

    # ИСПРАВЛЕНО: Используем restart вместо syncconf для избежания падения ядра с I-параметрами
    if systemctl is-active --quiet "awg-quick@${SERVER_AWG_NIC}"; then
        echo -e "${GREEN}Перезапуск сервиса для применения изменений...${NC}"
        systemctl restart "awg-quick@${SERVER_AWG_NIC}"
        echo -e "${GREEN}AmneziaWG сервис перезапущен.${NC}"
    fi

    echo "Client config created: ${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
}

function revokeClient() {
    NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "${SERVER_AWG_CONF}")
    if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
        echo "You have no existing clients!"
        return 1
    fi

    echo "Select the client to revoke:"
    grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | nl -s ') '
    
    local CLIENT_NUMBER=""
    local PROMPT="Select client [1-${NUMBER_OF_CLIENTS}]: "
    
    # Выводим приглашение
    echo -n "$PROMPT"
    
    while true; do
        # Читаем один символ без ожидания Enter
        read -s -n 1 KEY
        
        # Если нажат Enter
        if [[ -z "$KEY" ]]; then
            # Возвращаем курсор в начало строки и перезаписываем приглашение
            echo -en "\r\033[K$PROMPT"
            continue
        fi
        
        # Если введена цифра
        if [[ "$KEY" =~ [0-9] ]]; then
            CLIENT_NUMBER="$KEY"
            
            # Показываем введенную цифру
            echo -n "$KEY"
            
            # Читаем остальные цифры
            while true; do
                read -s -n 1 -t 0.5 NEXT_KEY
                if [[ -z "$NEXT_KEY" ]]; then
                    break
                fi
                if [[ "$NEXT_KEY" =~ [0-9] ]]; then
                    CLIENT_NUMBER="${CLIENT_NUMBER}${NEXT_KEY}"
                    echo -n "$NEXT_KEY"
                else
                    break
                fi
            done
            
            # Проверяем число
            if [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; then
                echo ""  # Переходим на новую строку
                break
            else
                echo -e "\r\033[K${PROMPT}Please enter a number between 1 and ${NUMBER_OF_CLIENTS}.\n$PROMPT"
                CLIENT_NUMBER=""
            fi
        else
            # Если не цифра
            echo -e "\r\033[K${PROMPT}Please enter a number.\n$PROMPT"
        fi
    done

    CLIENT_NAME=$(grep -E "^### Client" "${SERVER_AWG_CONF}" | sed -n "${CLIENT_NUMBER}"p | cut -d ' ' -f 3)
    
    if [[ -z "${CLIENT_NAME}" ]]; then
        echo -e "${RED}Error: Could not get client name${NC}"
        return 1
    fi

    sed -i "/^### Client ${CLIENT_NAME}\$/,/^$/d" "${SERVER_AWG_CONF}"

    HOME_DIR=$(getHomeDirForClient "${CLIENT_NAME}")
    CLIENT_CONF="${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
    if [[ -f "${CLIENT_CONF}" ]]; then
        rm -f "${CLIENT_CONF}"
    fi

    # ИСПРАВЛЕНО: Используем restart вместо syncconf для избежания падения ядра с I-параметрами
    if systemctl is-active --quiet "awg-quick@${SERVER_AWG_NIC}"; then
        echo -e "${GREEN}Перезапуск сервиса для применения изменений...${NC}"
        systemctl restart "awg-quick@${SERVER_AWG_NIC}"
        echo -e "${GREEN}AmneziaWG сервис перезапущен.${NC}"
    fi

    echo "Client ${CLIENT_NAME} revoked."
}

function showClientQR() {
    NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "${SERVER_AWG_CONF}")
    if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
        echo "No existing clients!"
        return 1
    fi

    echo "Select client to show QR:"
    grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | nl -s ') '
    
    local CLIENT_NUMBER=""
    local PROMPT="Select client [1-${NUMBER_OF_CLIENTS}]: "
    
    # Выводим приглашение
    echo -n "$PROMPT"
    
    while true; do
        # Читаем один символ без ожидания Enter
        read -s -n 1 KEY
        
        # Если нажат Enter
        if [[ -z "$KEY" ]]; then
            # Возвращаем курсор в начало строки и перезаписываем приглашение
            echo -en "\r\033[K$PROMPT"
            continue
        fi
        
        # Если введена цифра
        if [[ "$KEY" =~ [0-9] ]]; then
            CLIENT_NUMBER="$KEY"
            
            # Показываем введенную цифру
            echo -n "$KEY"
            
            # Читаем остальные цифры
            while true; do
                read -s -n 1 -t 0.5 NEXT_KEY
                if [[ -z "$NEXT_KEY" ]]; then
                    break
                fi
                if [[ "$NEXT_KEY" =~ [0-9] ]]; then
                    CLIENT_NUMBER="${CLIENT_NUMBER}${NEXT_KEY}"
                    echo -n "$NEXT_KEY"
                else
                    break
                fi
            done
            
            # Проверяем число
            if [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; then
                echo ""  # Переходим на новую строку
                break
            else
                echo -e "\r\033[K${PROMPT}Please enter a number between 1 and ${NUMBER_OF_CLIENTS}.\n$PROMPT"
                CLIENT_NUMBER=""
            fi
        else
            # Если не цифра
            echo -e "\r\033[K${PROMPT}Please enter a number.\n$PROMPT"
        fi
    done

    CLIENT_NAME=$(grep -E "^### Client" "${SERVER_AWG_CONF}" | sed -n "${CLIENT_NUMBER}"p | cut -d ' ' -f 3)
    
    if [[ -z "${CLIENT_NAME}" ]]; then
        echo -e "${RED}Error: Could not get client name${NC}"
        return 1
    fi
    
    HOME_DIR=$(getHomeDirForClient "${CLIENT_NAME}")
    CLIENT_CONF="${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
    
    if [[ ! -f "${CLIENT_CONF}" ]]; then
        echo -e "${RED}Client config file not found: ${CLIENT_CONF}${NC}"
        return 1
    fi
    
    # Выводим информацию о клиенте
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Client: ${CLIENT_NAME}${NC}"
    echo -e "${GREEN}Config file: ${CLIENT_CONF}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if command -v qrencode &>/dev/null; then
        echo -e "${GREEN}Here is your client config file as a QR Code for client ${CLIENT_NAME}:${NC}\n"
        qrencode -t ansiutf8 < "${CLIENT_CONF}"
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Client: ${CLIENT_NAME}${NC}"
        echo -e "${GREEN}Config file: ${CLIENT_CONF}${NC}"
        echo -e "${GREEN}========================================${NC}"
    else
        echo "qrencode is not installed. Displaying config file for client ${CLIENT_NAME}:"
        echo ""
        echo "========================================"
        echo "Client: ${CLIENT_NAME}"
        echo "Config file: ${CLIENT_CONF}"
        echo "========================================"
        echo ""
        cat "${CLIENT_CONF}"
        echo ""
        echo "========================================"
        echo "Client: ${CLIENT_NAME}"
        echo "========================================"
    fi
}

function manageMenu() {
    while true; do
        echo "AmneziaWG 2.0 server installer (https://github.com/potap1978/amneziawg-install_awg_v2.0)"
        echo ""                                     
        echo "           Периедай ПОТАПу привеД !!!!!!"
        echo ""
        echo "AmneziaWG client management"
        echo "  1) Add new client"
        echo "  2) Revoke existing client"
        echo "  3) Show client QR"
        echo "  4) Change I1-I5 parameters"
        echo "  5) Exit"
        
        local MENU_OPTION=""
        local MENU_PROMPT="Select an option [1-5]: "
        
        # Выводим приглашение
        echo -n "$MENU_PROMPT"
        
        while true; do
            # Читаем один символ без ожидания Enter
            read -s -n 1 KEY
            
            # Если нажат Enter
            if [[ -z "$KEY" ]]; then
                # Возвращаем курсор в начало строки и перезаписываем приглашение
                echo -en "\r\033[K$MENU_PROMPT"
                continue
            fi
            
            # Если введена цифра от 1 до 5
            if [[ "$KEY" =~ [1-5] ]]; then
                MENU_OPTION="$KEY"
                echo "$KEY"  # Показываем введенную цифру
                echo ""  # Переходим на новую строку
                break
            else
                # Если не цифра от 1 до 5
                echo -e "\r\033[K${MENU_PROMPT}Please enter a number between 1 and 5.\n$MENU_PROMPT"
            fi
        done
        
        case "${MENU_OPTION}" in
            1) newClient ;;
            2) revokeClient ;;
            3) showClientQR ;;
            4) changeIParams ;;
            5) exit 0 ;;
        esac
        
        # Пауза перед показом меню, чтобы пользователь увидел результат
        echo ""
        local CONTINUE_PROMPT="Press Enter to continue..."
        echo -n "$CONTINUE_PROMPT"
        read -s DUMMY
        echo ""  # Переходим на новую строку после нажатия Enter
    done
}

# Добавляем цветовые переменные, если их нет в окружении
if [[ -z "${RED}" ]]; then
    RED='\033[0;31m'
    ORANGE='\033[0;33m'
    GREEN='\033[0;32m'
    NC='\033[0m'
fi

loadParams
manageMenu
