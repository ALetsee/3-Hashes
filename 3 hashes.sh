#!/bin/bash

WORDS=(
    "pelota" "pez" "tigre" "mar" "tablet" "caja" "pantalla" "escritorio" "libreta" "Computadora"
    "escuela" "Silla" "mango" "casa" "teatro" "torta" "pasta" "serie" "descanso" "madera"
    "paulina" "copo"
)

generate_salt_pepper() {
    local salt_length=$((RANDOM % 9 + 8))
    local salt=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$salt_length")
    local pepper_length=$((RANDOM % 9 + 8))
    local pepper=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$pepper_length")
    echo "$salt" "$pepper"
}
# Primer codigo de clase
principal() {
    local text="$1"
    local hash_value=0
    local prime=31
    local mod_value=$((2**32 - 1))

    for ((i=0; i<${#text}; i++)); do
        char=$(printf "%d" "'${text:i:1}")
        hash_value=$(( (hash_value * prime + char + i*17) % mod_value ))
    done

    hash_value=$(( ((hash_value ^ (hash_value >> 16)) * 0x45d9f3b) % mod_value ))
    hash_value=$(( ((hash_value ^ (hash_value >> 16)) * 0x45d9f3b) % mod_value ))
    
    echo "$hash_value"
}
# Segundo codigo de clase
segundo_hash() {
    local key="$1"
    local seed=${2:-73}
    local length=${#key}
    local h=$seed
    local nblocks=$((length / 4))
    local c1=0xcc9e2d51
    local c2=0x1b873593
    
    for ((i=0; i<nblocks; i++)); do
        local k=0
        for ((j=0; j<4; j++)); do
            if [ $((i*4+j)) -lt $length ]; then
                k=$((k | ( $(printf "%d" "'${key:i*4+j:1}") << (j*8) ) ))
            fi
        done
        
        k=$(( (k * c1) & 0xFFFFFFFF ))
        k=$(( ((k << 15) | (k >> (32-15))) & 0xFFFFFFFF ))
        k=$(( (k * c2) & 0xFFFFFFFF ))
        h=$(( (h ^ k) & 0xFFFFFFFF ))
        h=$(( ((h << 13) | (h >> (32-13))) & 0xFFFFFFFF ))
        h=$(( (h * 5 + 0xE6546B64 + i) & 0xFFFFFFFF ))
    done
    
    local tail="${key:nblocks*4}"
    local tail_length=${#tail}
    if [[ $tail_length -gt 0 ]]; then
        local k=0
        for ((i=0; i<tail_length; i++)); do
            k=$((k | ( $(printf "%d" "'${tail:i:1}") << (i*8) ) ))
        done
        k=$(( (k * c1) & 0xFFFFFFFF ))
        k=$(( ((k << 15) | (k >> (32-15))) & 0xFFFFFFFF ))
        k=$(( (k * c2) & 0xFFFFFFFF ))
        h=$((h ^ k))
    fi
    
    h=$((h ^ length))
    h=$(( (h ^ (h >> 16)) & 0xFFFFFFFF ))
    h=$(( (h * 0x85EBCA6B) & 0xFFFFFFFF ))
    h=$(( (h ^ (h >> 13)) & 0xFFFFFFFF ))
    h=$(( (h * 0xC2B2AE35 + length) & 0xFFFFFFFF ))
    h=$(( (h ^ (h >> 16)) & 0xFFFFFFFF ))

    echo "$h"
}

# mi hashing

gen_hash() {
    local inp="$1"
    local salt="$2"
    local ppr="$3"
    local hsh_val=0
    local salt_len=${#salt}
    local ppr_len=${#ppr}
    local inp_len=${#inp}
    local itr=7
    
    hsh_val=$((inp_len * 0x9e3779b9))
    
    for ((i=0; i<salt_len && i<3; i++)); do
        hsh_val=$((hsh_val ^ ($(printf "%d" "'${salt:$i:1}") << (i*8+3))))
    done

    for ((i=0; i<ppr_len && i<3; i++)); do
        hsh_val=$((hsh_val ^ ($(printf "%d" "'${ppr:$i:1}") << (i*8+5))))
    done

    local combined_key="${inp}${salt:0:2}${ppr:0:2}"
    local combined_len=${#combined_key}

    for ((i=0; i<combined_len; i++)); do
        local chr_asc=$(printf "%d" "'${combined_key:$i:1}")
        chr_asc=$(( (chr_asc * (1 + i)) % 256 ))
        
        if [ $i -lt $inp_len ]; then
            chr_asc=$(( chr_asc ^ (i * 0x21) ))
        fi
        
        if [ $i -lt $salt_len ]; then
            chr_asc=$(( chr_asc + $(printf "%d" "'${salt:$i:1}") ))
        fi
        
        if [ $i -lt $ppr_len ]; then
            chr_asc=$(( chr_asc ^ ($(printf "%d" "'${ppr:$i:1}") << 4) ))
        fi
        
        for ((j=0; j<itr; j++)); do
            local mix=$(( (j * chr_asc) % 256 ))
            hsh_val=$(( hsh_val ^ (mix << (j % 16)) ))
            hsh_val=$(( hsh_val * 0x5bd1e995 + j*13 ))
            hsh_val=$(( hsh_val ^ (hsh_val >> (11 + j % 8)) ))
        done
        
        hsh_val=$(( hsh_val % 4294967296 ))
    done

    hsh_val=$(( hsh_val ^ (salt_len * 0x1234 + inp_len * 0x4321) ))
    hsh_val=$(( hsh_val ^ (ppr_len * 0x5678 + inp_len * 0x8765) ))
    hsh_val=$(( hsh_val * 0x9E3779B9 + inp_len ))
    hsh_val=$(( hsh_val ^ (hsh_val >> 16) ))
    
    if [ $inp_len -gt 0 ]; then
        hsh_val=$(( hsh_val ^ ($(printf "%d" "'${inp:0:1}") << 24) ))
    fi

    printf "%x\n" "$hsh_val"
}

hashear_palabras() {
    local salt="$1"
    local pepper="$2"
    
    local mixed_words=()
    for word in "${WORDS[@]}"; do
        mixed_words+=("$word")
    done
    
    for ((i=${#mixed_words[@]}-1; i>0; i--)); do
        j=$((RANDOM % (i+1)))
        temp="${mixed_words[i]}"
        mixed_words[i]="${mixed_words[j]}"
        mixed_words[j]="$temp"
    done
    

    echo "Resultados en" > resultados_hash.txt
    echo "------------------------------------" >> resultados_hash.txt
    
    local counter=1
    for palabra in "${mixed_words[@]}"; do

        {
            echo "Palabra #$counter: $palabra"
            echo "Metodo 1: $(principal "$palabra")"
            echo "Metodo 2: $(segundo_hash "$palabra")"
            echo "Metodo 3: $(gen_hash "$palabra" "$salt" "$pepper")"
            echo "------------------------------------"
        } >> resultados_hash.txt

        # Show colored output in terminal (solo darkblue y blanco)
        echo -e "\e[0;34m###############################################\e[0m"
        echo -e "\e[0;34m# \e[1;97mPalabra #$counter:\e[0m \e[1;97m$palabra\e[0m"
        echo -e "\e[0;34m###############################################\e[0m"
        echo -e "\e[0;34m# \e[1;97mMetodo 1:\e[0m \e[1;97m$(principal "$palabra")\e[0m"
        echo -e "\e[0;34m# \e[1;97mMetodo 2:\e[0m \e[1;97m$(segundo_hash "$palabra")\e[0m"
        echo -e "\e[0;34m# \e[1;97mMetodo 3:\e[0m \e[1;97m$(gen_hash "$palabra" "$salt" "$pepper")\e[0m"
        echo -e "\e[0;34m###############################################\e[0m"
        
        counter=$((counter + 1))
        sleep 0.1
    done
}

clear
echo -e "\e[0;34m"
cat << "EOF"


  _    _           _     _              
 | |  | |         | |   (_)             
 | |__| | __ _ ___| |__  _ _ __   __ _  
 |  __  |/ _` / __| '_ \| | '_ \ / _` | 
 | |  | | (_| \__ \ | | | | | | | (_| | 
 |_|  |_|\__,_|___/_| |_|_|_| |_|\__, | 
                                  __/ | 
                                 |___/  

                                                                                      
EOF
echo -e "\e[0m"
sleep 1

while true; do
    clear
    echo -e "\e[0;34m"
    cat << "EOF"


  _____           _                       _                       
 |_   _|         | |                     (_)                      
   | |  _ __  ___| |_ _ __ _   _  ___ ___ _  ___  _ __   ___  ___ 
   | | | '_ \/ __| __| '__| | | |/ __/ __| |/ _ \| '_ \ / _ \/ __|
  _| |_| | | \__ \ |_| |  | |_| | (_| (__| | (_) | | | |  __/\__ \
 |_____|_| |_|___/\__|_|   \__,_|\___\___|_|\___/|_| |_|\___||___/ By: ALetsee
                                                                  
                                                                  

EOF
    echo -e "\e[0m"


    echo -e "\e[0;34m##############################################################################################\\e[0m"
    echo -e "\e[0;34m#\e[1;97m   ≫ Generar la primera opción para un hashing más seguro si es que no tienes               \e[0;34m#\e[0m"
    echo -e "\e[0;34m#\e[1;97m   ≫ Insertar los datos que se obtuvo en la primera opción                                  \e[0;34m#\e[0m"
    echo -e "\e[0;34m#\e[1;97m   ≫ Se generará un .txt en la misma carpeta que el programa                                \e[0;34m#\e[0m"
    echo -e "\e[0;34m##############################################################################################\e[0m"
 
    echo -e 
        echo -e "\e[0;34m"
    cat << "EOF"

  _    _           _     _              
 | |  | |         | |   (_)             
 | |__| | __ _ ___| |__  _ _ __   __ _  
 |  __  |/ _` / __| '_ \| | '_ \ / _` | 
 | |  | | (_| \__ \ | | | | | | | (_| | 
 |_|  |_|\__,_|___/_| |_|_|_| |_|\__, | 
                                  __/ | 
                                 |___/  

EOF
    echo -e "\e[0m"
      echo -e "\e[0;34m###############################################\e[0m"
    echo -e "\e[0;34m#\e[1;97m          HASH MENU                          \e[0;34m#\e[0m"
    echo -e "\e[0;34m###############################################\e[0m"
    echo -e "\e[0;34m#\e[1;97m  [1] ≫ Generar Salt & Pepper                \e[0;34m#\e[0m"
    echo -e "\e[0;34m#\e[1;97m  [2] ≫ Generar Hashes                       \e[0;34m#\e[0m"
    echo -e "\e[0;34m#\e[1;97m  [3] ≫ Salir                                \e[0;34m#\e[0m"
    echo -e "\e[0;34m###############################################\e[0m"
    echo -e "\e[1;97m"
    read -p ">" choice
    echo -e "\e[0m"

    case $choice in
        1)
            clear
            echo -e "\e[0;34m###############################################\e[0m"
            echo -e "\e[0;34m#\e[1;97m      Generando Salt & Pepper                \e[0;34m#\e[0m"
            echo -e "\e[0;34m###############################################\e[0m"
            
            for i in {1..20}; do
                progress=$((i * 5))
                bar=$(printf "%${progress}s" | tr ' ' '█')
                echo -ne "\r\e[0;34m[${bar}] ${progress}%\e[0m"
                sleep 0.05
            done
            echo
            clear
            read -a salt_pepper <<< "$(generate_salt_pepper)"
            suggested_salt="${salt_pepper[0]}"
            suggested_pepper="${salt_pepper[1]}"

            echo -e "\e[0;34m###############################################\e[0m"
            echo -e "\e[0;34m#\e[1;97m SALT ≫\e[1;97m $suggested_salt\e[0m"
            echo -e "\e[0;34m#\e[1;97m PEPPER ≫\e[1;97m $suggested_pepper\e[0m"
            echo -e "\e[0;34m###############################################\e[0m"
            read -n 1 -s -r -p " [>]"
            ;;
        2)
            clear
            echo -e "\e[0;34m###############################################\e[0m"
            echo -e "\e[0;34m#\e[1;97m          Hash data                          \e[0;34m#\e[0m"
            echo -e "\e[0;34m###############################################\e[0m"
            
            echo -ne "\e[1;97m ≫  SALT: \e[1;97m"
            read user_salt
            echo -ne "\e[1;97m ≫  PEPPER: \e[1;97m"
            read user_pepper
            echo -e "\e[0m"
            
            clear
            echo -e "\e[0;34m###############################################\e[0m"
            echo -e "\e[0;34m#\e[1;97m        Generando hashes                     \e[0;34m#\e[0m"
            echo -e "\e[0;34m###############################################\e[0m"
            
            hashear_palabras "$user_salt" "$user_pepper"

            echo -e "\e[0;34m###############################################\e[0m"
            echo -e "\e[0;34m#\e[1;97m Resultados guardados en \e[1;97mresultados_hash.txt\e[1;97m \e[0;34m#\e[0m"
            echo -e "\e[0;34m###############################################\e[0m"
            read -n 1 -s -r -p " [>]"
            ;;
        3)
            clear
            echo -e "\e[0;34m###############################################\e[0m"
            echo -e "\e[0;34m#\e[1;97m           Saliendo                          \e[0;34m#\e[0m"
            echo -e "\e[0;34m###############################################\e[0m"
            for i in {1..20}; do
                progress=$((i * 5))
                bar=$(printf "%${progress}s" | tr ' ' '█')
                echo -ne "\r\e[0;34m[${bar}] ${progress}%\e[0m"
                sleep 0.05
            done
            echo
            exit 0
            ;;
        *)
            echo -e "\e[0;34m###############################################\e[0m"
            echo -e "\e[0;34m#\e[1;97m         Error                               \e[0;34m#\e[0m"
            echo -e "\e[0;34m###############################################\e[0m"
            sleep 1
            ;;
    esac
done