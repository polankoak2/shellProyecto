#!/bin/bash

# Verifica que se haya proporcionado un nombre de repositorio
if [ -z "$1" ]; then
  echo "Uso: $0 <url_del_repositorio>"
  exit 1
fi

# Clona el repositorio en un directorio temporal
REPO_URL=$1
TEMP_DIR=$(mktemp -d)
git clone --mirror "$REPO_URL" "$TEMP_DIR/repo" > /dev/null 2>&1

# Cambia al directorio temporal del repositorio
cd "$TEMP_DIR/repo" || { echo "Error al cambiar al directorio del repositorio"; exit 1; }

# Actualiza las referencias del repositorio
git fetch -p

# Obtiene una lista de ramas locales
local_branches=$(git branch -r | grep -v '\->' | sed 's/origin\///')

# Obtiene una lista de ramas remotas
remote_branches=$(git branch -r | grep 'origin/' | sed 's/origin\///')

# Encuentra ramas locales que no existen en el remoto
for branch in $local_branches; do
  if ! echo "$remote_branches" | grep -q "$branch"; then
    echo "Rama obsoleta local: $branch"
  fi
done

# Limpia el directorio temporal
rm -rf "$TEMP_DIR"
