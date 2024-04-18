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

#Zona del script

#Control de argumentos
while getopts "iohv" opcion; do
	case $opcion in
		i) leer_fichero ;;
		o) escribir_fichero ;;
		h) mostrar_ayuda; exit 0;;
		v) mostrar_version ;;
		?) mostrar_ayuda; exit 1
	esac
done

if [ $OPTIND -eq 1 ]; then #Esto hay que arreglarlo
	echo -e $rojo"$0 requiere un argumento."$fin_formato >&2; mostrar_ayuda; exit 1
fi
