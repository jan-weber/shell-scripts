#!/bin/bash

################################################################################
# Author: Jan Weber
# Date:   2023-07-14
# Version: 1.0
# Description: Skript pro smazání uživatelů v systému
#
# License: GNU/GPL verze 3
#
# Usage: sudo ./smazat-uzivatele.sh <user user2 user3>
#
# Example: sudo ./smazat-uzivatele.sh hon lucie ond pav emi
# Description: Skript nabidne smazan uzivatelu zacinajici na hon, lucie, ond, pav a emi
#
#
################################################################################

# pokud nejsou zadany zadne parametry, tak vypiseme napovedu a ukoncime skript
if [[ -z $@ ]]; then
	echo "Zadejte jména/počáteční znaky uživatelů, které chcete vymazat.";
	echo "smazat-uzivatele <user user2 user3>";
	exit 1;
fi

# promenna login_defs obsahuje cestu k souboru login.defs
login_defs="/etc/login.defs";

# promenna default_uid_min obsahuje defaultni minimalni UID
default_uid_min=1000;

# pokud existuje soubor login.defs
if [[ -f $login_defs ]]; then	
	# zjistime, jaky je minimalni UID	
	default_uid_min=$(grep "^UID_MIN" /etc/login.defs | tr -s " " | cut -d" " -f2);	
	# pokud jsme neziskali UID, tak pouzijeme defaultni hodnotu
	if [[ -z $default_uid_min ]]; then
		default_uid_min=1000;
	fi	
fi

# do promenne tmpfile ulozime cestu k docasnemu souboru
tmpfile=$(mktemp);

# projdeme vsechny parametry, ktere byly zadany
for uzivatelKeSmazani in $@; do		

	if [[ ${#uzivatelKeSmazani} -lt 2 ]]; then
		echo "Uživatelská jména musí mít minimálně dva znaky."
		echo "Zadali jste: $uzivatelKeSmazani";
		continue;
	fi

	# projdeme vsechny uzivatele v systemu
	while read -r uzivatel; do
		
		# pokud je UID mensi nez default_uid_min, tak preskocime
		[[ $(echo -n $uzivatel | cut -d: -f3) -ge $default_uid_min ]] || continue;		
		
		# pokud uzivatel odpovida zadanemu kriteriu, tak ho ulozime do docasneho souboru
		uzivatelJmeno=$(echo $uzivatel | cut -d: -f1);
		if [[ $uzivatelJmeno =~ ^$uzivatelKeSmazani  ]]; then			
			echo $uzivatelJmeno >> $tmpfile;
		fi
		
	done < /etc/passwd

done

# pokud nebyl nalezen zadny uzivatel, tak vypiseme chybu a ukoncime skript
if [[ ! -s $tmpfile ]]; then
	echo "Nebyl nalezen žádný uživatel, který by odpovídal zadaným kritériím.";
	exit 1;
fi

# projdeme uzivatele, ktere chceme smazat
for uzivatelJmeno in $(cat $tmpfile); do
	echo "Opravdu smazat uživatele $uzivatelJmeno vč. jeho domovské složky?";
	
	# zeptame se uzivatele, jestli chce smazat uzivatele
	read -p "Zadejte [ano|ne|storno]: " odpovedSmazat;
	
	# prevedeme odpoved na mala pismena
	odpovedSmazat=$(echo $odpovedSmazat | tr '[:upper:]' '[:lower:]');	

	# pokud je odpoved ano, tak smazeme uzivatele
	if [[ $odpovedSmazat == "ano" ]]; then
		userdel -r $uzivatelJmeno;
		if [[ $? -eq 0 ]]; then 
			echo "Uživatel $uzivatelJmeno BYL smazán.";				
		else
			echo "Došlo k chybě. Uživatel $uzivatelJmeno nebyl vymazán.";
		fi
	else # pokud je odpoved ne nebo storno vypiseme zpravu
		echo "Vymazání uživatele $uzivatelJmeno bylo zrušeno.";
		# pokud je odpoved storno, tak ukoncime skript
		if [[ $odpovedSmazat == "storno" ]]; then
		 	echo "Ukončuji skript.";
		  	exit 1;
		fi		
	fi
done

rm $tmpfile;