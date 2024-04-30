#! /usr/bin/env bash
#Autores: Francisco Javier Huete Mejías, Manuel Rodríguez Jurado
#Descripción:
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
		echo 'nmap está instalado.'
		return 0
	else
		echo 'nmap no está instalado. Se procederá a su instalación.'
		return 1
	fi
}


#Leer del fichero
leer_fichero () {
	fichero=$1
	for i in $(cat $fichero)
	do
		$(nmap -ns $i)
	done
}

#conexion con debian.org para instalar nmap
ping_debian () {
	echo 'Comprobando conexión a los repositorios Debian.'
	if ping -c 1 151.101.130.132; then
		return 0
	elif ping -c 1 151.101.2.132; then
		return 0
	elif ping -c 1 151.101.66.132; then
		return 0
	elif ping -c 1 151.101.194.132; then
		return 0
	else
		echo '[ERROR] - No tienes conexión a los repositorios de Debian.'
		exit 1
	fi
}

#Comprobar si soy root para instalar nmap
comprobar_root () {
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
	apt install nmap
}

#Zona del script

#Opciones
while getopts "iohv" opcion; do
	case $opcion in
		i) leer_fichero ;;
		o) escribir_fichero ;;
		h) mostrar_ayuda; exit 0;;
		v) mostrar_version ;;
		?) mostrar_ayuda; exit 1
	esac
done

#Validar si se aportan argumentos al script
if [ "$#" -eq 0 ]; then
	echo '[ERROR] - Este comando requiere, al menos, un argumento.'
	mostrar_ayuda
	exit 1
fi


#Comprobar si el paquete nmap está instalado
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


	



