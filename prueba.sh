#! /usr/bin/env bash
#Comprobar si soy root para instalar nmap
comprobar_root () {
	if [ $(whoami) = 'root' ]; then
        echo 'Tienes privilegios para instalar nmap'
		return 0
	else
        echo 'debes de ser root'
		exit 1
	fi
}

comprobar_root