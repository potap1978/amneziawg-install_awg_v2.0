#!/bin/bash

AMNEZIAWG_DIR="/etc/amnezia/amneziawg"

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
}

# Function to change I parameters
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
        until [[ ${CHOICE} =~ ^[1-6]$ ]]; do
            read -rp "Select parameter to change [1-6]: " CHOICE
        done
        
        case "${CHOICE}" in
            1)
                echo ""
                echo "Current I1 value: ${SERVER_AWG_I1}"
                read -rp "Enter new I1 value (or press Enter to keep current): " NEW_VALUE
                if [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I1="${NEW_VALUE}"
                    echo -e "\033[0;32mI1 updated successfully\033[0m"
                    saveIParams
                else
                    echo -e "\033[0;33mI1 unchanged\033[0m"
                fi
                ;;
            2)
                echo ""
                echo "Current I2 value: ${SERVER_AWG_I2:-<not set>}"
                read -rp "Enter new I2 value (or press Enter to keep current, 'none' to remove): " NEW_VALUE
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I2=""
                    echo -e "\033[0;32mI2 removed\033[0m"
                    saveIParams
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I2="${NEW_VALUE}"
                    echo -e "\033[0;32mI2 updated successfully\033[0m"
                    saveIParams
                else
                    echo -e "\033[0;33mI2 unchanged\033[0m"
                fi
                ;;
            3)
                echo ""
                echo "Current I3 value: ${SERVER_AWG_I3:-<not set>}"
                read -rp "Enter new I3 value (or press Enter to keep current, 'none' to remove): " NEW_VALUE
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I3=""
                    echo -e "\033[0;32mI3 removed\033[0m"
                    saveIParams
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I3="${NEW_VALUE}"
                    echo -e "\033[0;32mI3 updated successfully\033[0m"
                    saveIParams
                else
                    echo -e "\033[0;33mI3 unchanged\033[0m"
                fi
                ;;
            4)
                echo ""
                echo "Current I4 value: ${SERVER_AWG_I4:-<not set>}"
                read -rp "Enter new I4 value (or press Enter to keep current, 'none' to remove): " NEW_VALUE
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I4=""
                    echo -e "\033[0;32mI4 removed\033[0m"
                    saveIParams
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I4="${NEW_VALUE}"
                    echo -e "\033[0;32mI4 updated successfully\033[0m"
                    saveIParams
                else
                    echo -e "\033[0;33mI4 unchanged\033[0m"
                fi
                ;;
            5)
                echo ""
                echo "Current I5 value: ${SERVER_AWG_I5:-<not set>}"
                read -rp "Enter new I5 value (or press Enter to keep current, 'none' to remove): " NEW_VALUE
                if [[ "${NEW_VALUE}" == "none" ]]; then
                    SERVER_AWG_I5=""
                    echo -e "\033[0;32mI5 removed\033[0m"
                    saveIParams
                elif [[ -n "${NEW_VALUE}" ]]; then
                    SERVER_AWG_I5="${NEW_VALUE}"
                    echo -e "\033[0;32mI5 updated successfully\033[0m"
                    saveIParams
                else
                    echo -e "\033[0;33mI5 unchanged\033[0m"
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
            read -rp "Press Enter to continue..." DUMMY
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
    
    echo -e "\033[0;32mI parameters saved successfully\033[0m"
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

    until [[ ${CLIENT_NAME} =~ ^[a-zA-Z0-9_-]+$ && ${CLIENT_EXISTS} == '0' && ${#CLIENT_NAME} -lt 16 ]]; do
        read -rp "Client name: " -e CLIENT_NAME
        CLIENT_EXISTS=$(grep -c -E "^### Client ${CLIENT_NAME}\$" "${SERVER_AWG_CONF}")
        if [[ ${CLIENT_EXISTS} != 0 ]]; then
            echo "A client with this name already exists, please choose another."
        fi
    done

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

    awg syncconf "${SERVER_AWG_NIC}" <(awg-quick strip "${SERVER_AWG_NIC}")

    echo "Client config created: ${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
}

function revokeClient() {
    NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "${SERVER_AWG_CONF}")
    if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
        echo "You have no existing clients!"
        exit 1
    fi

    echo "Select the client to revoke:"
    grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | nl -s ') '
    read -rp "Select client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER

    CLIENT_NAME=$(grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)

    sed -i "/^### Client ${CLIENT_NAME}\$/,/^$/d" "${SERVER_AWG_CONF}"

    HOME_DIR=$(getHomeDirForClient "${CLIENT_NAME}")
    rm -f "${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"

    awg syncconf "${SERVER_AWG_NIC}" <(awg-quick strip "${SERVER_AWG_NIC}")

    echo "Client ${CLIENT_NAME} revoked."
}

function showClientQR() {
    NUMBER_OF_CLIENTS=$(grep -c -E "^### Client" "${SERVER_AWG_CONF}")
    if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
        echo "No existing clients!"
        exit 1
    fi

    echo "Select client to show QR:"
    grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | nl -s ') '
    read -rp "Select client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER

    CLIENT_NAME=$(grep -E "^### Client" "${SERVER_AWG_CONF}" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
    HOME_DIR=$(getHomeDirForClient "${CLIENT_NAME}")
    
    if command -v qrencode &>/dev/null; then
        qrencode -t ansiutf8 < "${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
    else
        echo "qrencode is not installed. Cannot display QR code."
        cat "${HOME_DIR}/${SERVER_AWG_NIC}-client-${CLIENT_NAME}.conf"
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
        read -rp "Select an option [1-5]: " MENU_OPTION
        
        case "${MENU_OPTION}" in
            1) newClient ;;
            2) revokeClient ;;
            3) showClientQR ;;
            4) changeIParams ;;
            5) exit 0 ;;
            *) echo "Invalid option. Please select 1-5." ;;
        esac
        
        # Пауза перед показом меню, чтобы пользователь увидел результат
        echo ""
        read -rp "Press Enter to continue..." DUMMY
    done
}

loadParams
manageMenu
