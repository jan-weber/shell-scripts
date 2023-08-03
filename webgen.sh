#!/bin/bash

# Funkce pro načtení cest k textovým souborům z adresáře
# parametry: cesta k adresáři, pole, do kterého se budou ukládat cesty k souborům
nactiSoubory() {
	local cesta="${1%/}"; # Odstranění lomítka na konci cesty.	
	local -n soubory=$2; # Nastavení reference na pole, které bude vraceno z funkce.

	for soubor in $(ls $cesta); do	
		cestaSoubor="$cesta/$soubor";		
		if file -b $cestaSoubor | grep -iq "text"; then				
			echo "nacitam soubor: $cestaSoubor";
			soubory+=($cestaSoubor);		
		fi
	done

	echo "celkem nalezeno textovych souboru: ${#soubory[@]}";

	if [[ ${#soubory[@]} -eq 0 ]]; then
		echo "Zadany adresar neobsahuje zadne textove soubory, ukoncuji program";
		exit 1;
	fi
}

Kontrola, zda je zadána hodnota celé číslo
# parametry: hodnota
jeCeleCislo() {
	if [[ $1 =~ ^[0-9]+$ ]]; then
		return 0; 				
	else
		return 1;
	fi	
}

# Uložení cesty k adresáři s daty, odstranění lomítka na konci cesty
adresarData="$1";

# Pokud zadaná cesta neexistuje nebo nejde o adresář, vypíšeme všechny adresáře z místa, kde je uložen skript
# Požádáme uživatele o výběr adresáře a uděláme kontrolu na vstupní hodnoty uživatele
# Uložíme cestu k adresáři s daty
if [[ -z "$adresarData" || ! -d "$adresarData"  ]] ; then
	
	adresare=("./");
	echo "1) aktualni adresar ./";	
	i=1;	

	for soubor in *; do	
		# Pokud jde o adresář šablony, přeskočíme jeho zpracování
		[[ $soubor == "sablony" ]] && continue;

		# Pokud jde o adresář, vypíšeme ho a uložíme do pole
		if [[ -d $soubor ]]; then
			((i++));
			echo "$i) $soubor";
			adresare+=("$soubor");
		fi
	done		
	
	read -p "Zadejte číslo adresáře, kde jsou data pro vytvářený web a stiskněte enter: " cisloAdresare;

	if [[ -z "$cisloAdresare" ]]; then 
	       echo "Nevybrali jste žádný adresář, ukončuji program";
	       exit 1;
	fi

	# Kontrola, zda je zadána hodnota celé číslo
	if ! jeCeleCislo "$cisloAdresare"; then
		echo "nezadali jste číslo, ukončuji program";
		exit 1;
	fi

	# Kontrola, zda je číslo adresáře v rozsahu pole
	if [[ $cisloAdresare -gt 0  && $cisloAdresare -le ${#adresare[@]} ]]; then
		((cisloAdresare--)); # Pole se indexuje od 0, uzivatel zadava od 1
		adresarData=${adresare[$cisloAdresare]};
		echo "jméno vybraného adresáře: $adresarData";
	else
		echo "Zadali jste číslo mimo uvedený rozsah";
		exit 1;
	fi
fi

# Definice pole, do kterého se budou ukládat cesty k souborům
declare -a souboryPole;
nactiSoubory "$adresarData" souboryPole;

# echo ${souboryPole[@]};
# TODO: Zpracovat data, přenést do šablon, vygenerovat web
