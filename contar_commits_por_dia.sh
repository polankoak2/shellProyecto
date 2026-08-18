#!/bin/bash

# CONFIGURACIÓN: Reemplaza con la URL de tu repositorio
URL_REPOSITORIO="git@github.com:polankoak2/proyectoTitulo.git"
ARCHIVO_LOG="/Users/polankoak/Documents/IACC/2026/proyTitulo/salida/commits_por_rama.txt"
CARPETA_TEMPORAL="/Users/polankoak/Documents/IACC/2026/temp"

# 1. Clonar el repositorio de forma rápida (solo metadatos, sin descargar archivos pesados)
git clone --bare "$URL_REPOSITORIO" "$CARPETA_TEMPORAL"
cd "$CARPETA_TEMPORAL" || exit

# 2. Generar el reporte incremental
echo "==========================================" >> "$ARCHIVO_LOG"
echo "Ejecución: $(date '+%Y-%m-%d %H:%M:%S')" >> "$ARCHIVO_LOG"
echo "==========================================" >> "$ARCHIVO_LOG"

# Contar commits de todas las ramas
git for-each-ref --format='%(refname:short)' refs/heads/ | while read -r rama; do

    if [ "$rama" = "main" ] || [ "$rama" = "master" ] || [ "$rama" = "develop" ]; then
        continue # Salta esta rama y pasa a la siguiente
    fi

    _total_commits=$(git rev-list --count "$rama")
    echo "Rama: $rama | Commits: $_total_commits" >> "$ARCHIVO_LOG"
done

echo "" >> "$ARCHIVO_LOG"

# 3. Limpieza: Salir y borrar la carpeta clonada
cd ..
rm -rf "$CARPETA_TEMPORAL"

echo "Conteo guardado exitosamente en $ARCHIVO_LOG"
