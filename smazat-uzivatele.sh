#!/bin/bash

# Author: Jan Weber
# Description: Skript pro smazání uživatelů v testovacím prostředí systému Linux
# License: GNU/GPL verze 3
# Usage: smazat-uzivatele.sh <user user2 user3 *>
# Parametrs: <user user2 user3 *> - jména nebo části jmen uživatelů, které chceme smazat
# Example: sudo ./smazat-uzivatele.sh hon lucie ond pav emi



# pokud nejsou zadany zadne parametry, tak vypiseme napovedu a ukoncime skript
if [[ $# -eq 0 ]]; then
	echo "Zadejte jména/počáteční znaky uživatelů, které chcete vymazat.";
	echo "Pouziti: $0 <user user2 user3>";
	exit 1;
fi
# zjistime defaultni min ID uzivatelu
default_uid_min=$(grep "^UID_MIN" /etc/login.defs | tr -s " " | cut -d" " -f2);	
 
if [[ -z $default_uid_min ]]; then
	default_uid_min=1000;
fi

odpovidajici_uzivatele=();

# projdeme vsechny parametry, ktere byly zadany
for castecne_jmeno in $@; do		

	if [[ ${#castecne_jmeno} -lt 2 ]]; then
		echo "Uživatelská jména musí mít minimálně dva znaky."
		echo "Zadali jste: $castecne_jmeno";
		continue;
	fi

	# projdeme vsechny uzivatele v systemu
	while read -r uzivatel; do		
		
		# pokud je UID mensi nez default_uid_min, tak preskocime
		[[ $(echo -n $uzivatel | cut -d: -f3) -ge $default_uid_min ]] || continue;		

		# pokud uzivatel odpovida zadanemu kriteriu, tak ho ulozime do docasneho souboru
		uzivatel_jmeno=$(echo $uzivatel | cut -d: -f1);
		if [[ $uzivatel_jmeno =~ ^$castecne_jmeno  ]]; then			
			odpovidajici_uzivatele+=($uzivatel_jmeno);
		fi
		
	done < /etc/passwd

done

# pokud nebyl nalezen zadny uzivatel, tak vypiseme chybu a ukoncime skript
if [[ ${#odpovidajici_uzivatele[@]} -eq 0 ]]; then
	echo "Nebyl nalezen žádný uživatel, který by odpovídal zadaným kritériím.";
	exit 1;
fi

# projdeme uzivatele, ktere chceme smazat
for uzivatel_jmeno in ${odpovidajici_uzivatele[@]}; do
	echo "Opravdu smazat uživatele $uzivatel_jmeno vč. jeho domovské složky?";
	
	# zeptame se uzivatele, jestli chce smazat uzivatele
	read -p "Zadejte [ano|ne|storno]: " odpoved_smazat;
	
	# prevedeme odpoved na mala pismena
	odpoved_smazat=$(echo $odpoved_smazat | tr '[:upper:]' '[:lower:]');	

	# pokud je odpoved ano, tak smazeme uzivatele
	if [[ $odpoved_smazat == "ano" ]]; then
		userdel -r $uzivatel_jmeno;
		if [[ $? -eq 0 ]]; then 
			echo "Uživatel $uzivatel_jmeno BYL smazán.";				
		else
			echo "Došlo k chybě. Uživatel $uzivatel_jmeno nebyl vymazán.";
		fi
	else # pokud je odpoved ne nebo storno vypiseme zpravu
		echo "Vymazání uživatele $uzivatel_jmeno bylo zrušeno.";
		# pokud je odpoved storno, tak ukoncime skript
		if [[ $odpoved_smazat == "storno" ]]; then
		 	echo "Ukončuji skript.";
		  	exit 1;
		fi		
	fi
done