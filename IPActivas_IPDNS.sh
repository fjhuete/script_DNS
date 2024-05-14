#! /usr/bin/env sh
#Autores: Francisco Javier Huete Mejías, Manuel Rodríguez Jurado
#Descripción: Recibe un rango de direcciones IP y lista las que están activas 
#y las que están en el DNS.
#Versión: 1.41
#Fecha: 14-05-2024
#Zona de depuración
        #Inicio de la zona de depuración con set -x (descomentar para activar)
#set -x
        #Advertencia de falta de variable (descomentar para activar)
 #set -u
#Zona de declaración de variables

#Color de texto
rojo="\e[1;31m"
verde="\e[1;32m"

#Formato
negrita="\e[1m"
parpadeo="\e[1;5m"

fin_formato="\e[0m"

#Expresión regular para identificar si una cadena de caracteres es una IP
regexp_ip="^(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
			25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
			25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
			25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)$"

#Expresión regular para identificar redes
regexp_red="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}(\
[0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\
\/(3[0-2]|[1-2][0-9]|[0-9]))$"

#Zona de declaración de funciones

mostrar_ayuda() {
echo -e ""$negrita"Uso:"$fin_formato" $0  [-a IP | -i FICHERO | -o [IP | \
FICHERO_ENTRADA] FICHERO_SALIDA]
"$negrita"Descripción:"$fin_formato" Recibe un rango de direcciones IP y \
lista las que están activas y las que están en el DNS.
"$negrita"Parámetros aceptados:"$fin_formato"
	-a 		Lee la dirección IP o de red indicada como argumento y comprueba si \
está activa y en la caché DNS. Esta opción acepta como parámetro una \
dirección IP o una dirección de red CIDR.
	-i <FICHERO>	Lee las direcciones IP o de red de un fichero y comprueba si \
está activa y en la caché DNS. Este fichero debe contener una dirección IP \
o una dirección de red CIDR por cada línea.
	-o <FICHERO>	Escribe la salida a un fichero. Si el fichero no existe, \
	lo crea.
	-h 		Muestra esta ayuda.
	-v 		Muestra la versión.
	
"$negrita"Ejemplos de uso:"$fin_formato"

Para ver las direcciones disponibles en la red 172.22.0.0/24 y cuáles de ellas \
están en el DNS:
	$0 -a 172.22.0.0/24
	
Para leer las direcciones de un fichero y buscar cuáles están disponibles y \
cuáles en el DNS:
	$0 -i direcciones.txt
	
Para guardar la salida del script en un fichero de texto:
	$0 -o 172.22.0.0/24 FicheroDeSalida.txt
	$0 -o direcciones.txt FicheroDeSalida.txt
	
Este script lee un argumento de la entrada estándar con la opción -a o uno o \
varios argumentos de un fichero con la opción -i. El formato del fichero de \
entrada debe ser una dirección IP o una dirección de red CIDR por cada línea.
"$negrita"Ejemplo de fichero:"$fin_formato"
	\"172.22.0.1
	172.22.0.14
	172.22.0.168\"
	
	
Este script se ejecuta en una subshell."
}

mostrar_version() {
	echo "$0 Versión: 1.41"
	exit 0
}

obtener_DNS(){
	DNS=$(cat /etc/resolv.conf | grep -m 1 '^nameserver' | awk '{print $2}')
	if [[ $DNS =~ $regexp_ip ]]; then
		return 0
	else
		echo "$rojo$negrita[ERROR]$fin_formato - No es posible obtener el DNS de \
/etc/resolv.conf"
		exit 1
	fi
}


instalar_nslookup(){
	comprobar_root
	echo 'Instalando nslookup.'
	apt update && apt upgrade -y
	apt install -y dnsutils
}

validar_nslookup() {
	if command -v nslookup &>/dev/null; then
		echo -e "$verde[OK]$fin_formato La herramienta nslookup está instalada."
	else
		echo -e "$rojo$negrita[ERROR]$fin_formato La herramienta nslookup no está \
instalada."
		comprobar_root
		instalar_nslookup
	fi
	
}


#Comprobar si está instalado el paquete nmap
nmap_instalado () {
	echo -e "Comprobando si el paquete nmap está \
instalado"$parpadeo"_$fin_formato"
	local paquete="nmap"
	if dpkg -l | grep -q "^ii\s*$paquete\s"; then
		return 0
	else
		echo 'nmap no está instalado. Se procederá a su instalación.'
		return 1
	fi
}

#conexion con debian.org para instalar nmap
ping_debian () {
	echo -e "Comprobando conexión a los repositorios \
Debian"$parpadeo"_$fin_formato"
	if ping -c 1 -W 1 151.101.130.132 &> /dev/null; then
		echo 'Conexión exitosa a los repositorios.'
		return 0
	elif ping -c 1 -W 1 151.101.2.132 &> /dev/null; then
		echo 'Conexión exitosa a los repositorios.'
		return 0
	elif ping -c 1 -W 1 151.101.66.132 &> /dev/null; then
		echo 'Conexión exitosa a los repositorios.'
		return 0
	elif ping -c 1 -W 1 151.101.194.132 &> /dev/null; then
		echo 'Conexión exitosa a los repositorios.'
		return 0
	else
		echo -e "$rojo$negrita[ERROR]$fin_formato - No tienes conexión a los \
repositorios de Debian."
		exit 1
	fi
}

#Comprobar si soy root para instalar nmap
comprobar_root () {
	echo 'Comprobando privilegios del usuario.'
	if [ $(whoami) = 'root' ]; then
		return 0
	else
        echo -e "$rojo$negrita[ERROR]$fin_formato - Debes de ser root."
		exit 1
	fi
}

#instalar nmap
instalar_nmap () {
	echo -e "Instalando nmap"$parpadeo"_$fin_formato"
	apt update && apt upgrade -y
	apt install -y nmap
}

#Función que valida si nmpa está instalado y, si no lo está, lo instala.
validar_nmap () {
	nmap_instalado
	if [ "$?" -eq 1 ]
	then
		#Comprobar si hay conexión a los repositorios de Debian
		ping_debian
		if 	[ "$?" -eq 0 ]; then
			#Comprueba que eres root de ser asi instala nmap
			comprobar_root
			instalar_nmap
			echo -e "$verde[OK]$fin_formato - nmap instalado"
		fi
	else
		echo -e "$verde[OK]$fin_formato - nmap instalado"
	fi
}

#Valida si la IP tiene un formato correcto
validar_IP () {
	i=$1
	if [[ $i =~ $regexp_ip ]] || [[ $i =~ $regexp_red ]]; then
		return 0
	else
    echo -e "$rojo$negrita[ERROR]$fin_formato - La dirección IP no es \
válida: $i"
		exit 1
	fi
}

#Leer una dirección IP pasada como argumento
leer_direccion () {
    i=$1
  #Ejecuta nmap y guarda la salida del comando en un fichero temporal
    nmap -sn -v "$i" | grep "Nmap scan report for" &>contenido_tmp.txt
  # Leer el fichero temporal campo a campo usando un bucle while
    while IFS= read -r line; do
   # Extraer la dirección IP de la línea
        ip=$(echo "$line" | awk '{print $5}')
    # Comprobar si la línea contiene "host down"
        if [[ "$line" == *"host down"* ]]; then
            echo "$ip: Disponible"
        else
            obtener_DNS
                if nslookup "$ip" "$DNS" | grep "^\*\*" &>/dev/null; then
                  echo "$ip: No disponible. No hay resolución para este nombre."
                else
                  echo "$ip: No disponible. Dominios:"
                  nslookup "$ip" "$DNS" | echo -e "$(awk '{ print $4 }')"
                fi
        fi
        done <contenido_tmp.txt
}


#Validar si existe un fichero
validar_fichero() {
	if [ ! -f "$1" ]; then
		echo -e "$rojo$negrita[ERROR]$fin_formato - El archivo '$1' no existe."
		exit 1
	else
		return 0
	fi
}

# Leer del fichero
leer_fichero() {
    fichero=$1
	validar_fichero $fichero
    echo -e "Buscando las direcciones disponibles"$parpadeo"_$fin_formato"
    touch contenido_tmp.txt
    #Lee cada línea del fichero
    for i in $(cat "$fichero"); do
        validar_IP $i
        #Ejecuta nmap y guarda la salida del comando en un fichero temporal
        nmap -sn -v "$i" | grep "Nmap scan report for" &>contenido_tmp.txt
        # Leer el fichero temporal campo a campo usando un bucle while
        while IFS= read -r line; do
        # Extraer la dirección IP de la línea
            ip=$(echo "$line" | awk '{print $5}')
            # Comprobar si la línea contiene "host down"
            if [[ "$line" == *"host down"* ]]; then
                echo "$ip: Disponible"
            else
                obtener_DNS
                if nslookup "$ip" "$DNS" | grep "^\*\*" &>/dev/null; then
	                echo "$ip: No disponible. No hay resolución para este nombre."
                else
                    echo "$ip: No disponible. Dominios:"
                    nslookup "$ip" "$DNS" | echo -e "$(awk '{ print $4 }')"
                fi
            fi
        done <contenido_tmp.txt
    done
    # Eliminar el archivo temporal
    rm contenido_tmp.txt
}


#Escribir a fichero
escribir_fichero () {
	entrada=$2
	salida=$3
	#Comprueba si existe el fichero de salida
	if [ ! -f "$salida" ]; then
		echo "Creando fichero de salida"
		touch $3
	fi
	#Comprueba si existe el fichero de entrada
	if [ -f "$entrada" ]; then
		#Si existe, lee del fichero de entrada y escribe en el fichero de salida
		echo -e "Buscando las direcciones disponibles"$parpadeo"_$fin_formato"
		leer_fichero $entrada > $salida
	else
		#Si no existe, lee la dirección IP aportada como argumento y escribe 
		#en el fichero de salida
		echo -e "Buscando las direcciones disponibles"$parpadeo"_$fin_formato"
		leer_direccion $entrada > $salida
	fi
}

#Zona del script

#Opciones
while getopts "aiohv" opcion; do
	case $opcion in
		a) validar_IP $2; obtener_DNS; validar_nslookup; validar_nmap; 
		leer_direccion $2; exit 0 ;;
		i) obtener_DNS; validar_nslookup; validar_nmap; leer_fichero $2; exit 0 ;;
		o) validar_nmap; escribir_fichero $@; exit 0 ;;
		h) mostrar_ayuda; exit 0;;
		v) mostrar_version; exit 0 ;;
		?) mostrar_ayuda; exit 1 ;;
	esac
done

#Validar si se aportan argumentos al script
if [ "$#" -eq 0 ]; then
	echo -e "$rojo$negrita[ERROR]$fin_formato - Este comando requiere, al menos, \
un argumento."
	mostrar_ayuda
	exit 1
fi
