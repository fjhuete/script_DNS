#! /usr/bin/env bash
#Autores: Francisco Javier Huete Mejías, Manuel Rodríguez Jurado
#Descripción: Recibe un rango de direcciones IP y lista las que están activas y las que están en el DNS.
#Versión: 1.0
#Fecha:
#Zona de depuración
        #Inicio de la zona de depuración con set -x (descomentar para activar)
#set -x
        #Advertencia de falta de variable (descomentar para activar)
 #set -u
#Zona de declaración de variables

#Color de texto
rojo="\e[1;31m"
verde="\e[1;32m"
amarillo="\e[1;33m"
azul="\e[1;34m"
morado="\e[1;35m"
cyan="\e[1;36m"

#Color de fondo
gris="\e[1;40m"
verde="\e[1;42m"
amarillo="\e[1;44m"
azul="\e[1;44m"
morado="\e[1;45m"
cyan="\e[1;46m"

#Formato
negrita="\e[1m"
subrayado="\e[4m"
parpadeo="\e[1;5m"
invertido="\e[1;7m"


fin_formato="\e[0m"

#Expresión regular para identificar si una cadena de caracteres es una IP
regexp_ip="^(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
			25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
			25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.( 
			25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)$"

#Expresión regular para identificar redes
regexp_red_ip="^(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][1-9]?)\. 
    (25[0-5]|2[0-4][0-9]|[0-1]?[0-9][1-9]?)\. 
    (25[0-5]|2[0-4][0-9]|[0-1]?[0-9][1-9]?)\. 
    (0)\/(3[0-1]|[1-2]?\d)$"

#Expresión regular para identificar redes en decimal puntuada
regexp_red_hexadecimal="^(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][1-9]?)\. 
    (25[0-5]|2[0-4][0-9]|[0-1]?[0-9][1-9]?)\. 
    (25[0-5]|2[0-4][0-9]|[0-1]?[0-9][1-9]?)\. 
    (0)\ (255|254|252|248|240|224|192|128|0)\. 
    (255|254|252|248|240|224|192|128|0)\. 
    (255|254|252|248|240|224|192|128|0)\. 
    (255|254|252|248|240|224|192|128|0)$"

#Zona de declaración de funciones

mostrar_ayuda() {
echo "Uso: $0 [IP | Dirección de red | -i FICHERO][-o FICHERO]
Descripción: Recibe un rango de direcciones IP y lista las que están activas y las que están en el DNS.
Parámetros aceptados:
	-i <FICHERO>	Lee las direcciones IP de un fichero. Si no se indica, toma como dirección IP el primer argumento.
	-o <FICHERO>	Escribe la salida a un fichero. Si no se indica, muestra el resultado por la salida estándar.
	-h 		Muestra esta ayuda.
	-v 		Muestra la versión."
}

mostrar_version() {
	echo "$0 Versión: 1.0"
	exit 0
}

#Comprobar si está instalado el paquete nmap
nmap_instalado () {
	echo 'Comprobando si el paquete nmap está instalado.'
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
	echo 'Comprobando conexión a los repositorios Debian.'
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
		echo '[ERROR] - No tienes conexión a los repositorios de Debian.'
		exit 1
	fi
}

#Comprobar si soy root para instalar nmap
comprobar_root () {
	echo 'Comprobando privilegios del usuario.'
	if [ $(whoami) = 'root' ]; then
		return 0
	else
        echo ' [ERROR] - Debes de ser root.'
		exit 1
	fi
}


#instalar nmap
instalar_nmap () {
	echo 'Instalando nmap.'
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
		fi
	fi
}

#Leer una dirección IP pasada como argumento
leer_direccion () {
	ip=$1
	echo $(nmap -ns $ip)
}

#Leer del fichero
leer_fichero () {
	#Valida si el fichero existe
	if [ ! -f "$1" ]; then
	    echo "[ERROR] - El archivo '$1' no existe."
	    exit 1
	else
		fichero=$1
		for i in $(cat $fichero)
		do
			$(nmap -sn $i | grep "Host seems down") &> /dev/null
			if [ "$?" -eq 127 ]; then
				echo "$i: Disponible "
			else
				echo "$i: No disponible"
			fi
		done
	fi
}



#Escribir a fichero
escribir_fichero () {
	entrada=$2
	salida=$3
	#Comprueba si existe el fichero de salida
	if [ ! -f "$salida" ]; then
		touch $3
		echo "CREANDO FICHERO"
		#echo "[ERROR] - El archivo '$salida' no existe."
	fi
	#Comprueba si existe el fichero de entrada
	if [ -f "$entrada" ]; then
		#Si existe, lee del fichero de entrada y escribe en el fichero de salida
		leer_fichero $entrada > $salida
	else
		#Si no existe, lee la dirección IP aportada como argumento y escribe en el fichero de salida
		leer_direccion $entrada > $salida
	fi

}

#Zona del script

#Opciones
while getopts "iohv" opcion; do
	case $opcion in
		o) validar_nmap; escribir_fichero $@; exit 0 ;;
		i) validar_nmap; leer_fichero $2; exit 0 ;;
		h) mostrar_ayuda; exit 0;;
		v) mostrar_version; exit 0 ;;
		$regexp_ip) validar_nmap; leer_direccion $1; exit 0 ;;
		$regex_ip_red) validar_nmap; leer_direccion $1; exit 0;;
		$regexp_red_hexadecimal) validar_nmap; leer_direccion $1; exit 0;;
		?) mostrar_ayuda; exit 1 ;;
	esac
done

#Validar si se aportan argumentos al script
if [ "$#" -eq 0 ]; then
	echo '[ERROR] - Este comando requiere, al menos, un argumento.'
	mostrar_ayuda
	exit 1
fi




	



