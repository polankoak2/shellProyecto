#!/bin/bash

# ==========================================
# CONFIGURACIÓN DEL USUARIO
# ==========================================
DRY_RUN=true

# Configuración de Rutas
REPO_URL="git@github.com:polankoak2/proyectoTitulo.git"
REPO_PATH="/Users/polankoak/Documents/IACC/2026/proyTitulo/proyectoTitulo_temporal"
OUTPUT_FILE="/Users/polankoak/Documents/IACC/2026/proyTitulo/salida/branches.txt"
GIT_CMD="/usr/bin/git"

# ==========================================
# INICIO DEL PROCESO
# ==========================================

# Asegurar que el directorio exista
mkdir -p "$(dirname "$OUTPUT_FILE")"

# NOTA: Ahora usamos '>>' para conservar todo el registro anterior
echo "" >> "$OUTPUT_FILE"
echo "=====================================================================" >> "$OUTPUT_FILE"
if [ "$DRY_RUN" = true ]; then
    echo " REPORTE DE SIMULACIÓN: RAMAS DETECTADAS PARA BORRAR (>30 DÍAS)" >> "$OUTPUT_FILE"
    echo " [AVISO] Ninguna rama ha sido eliminada del servidor remoto." >> "$OUTPUT_FILE"
else
    echo " REPORTE REAL: RAMAS ELIMINADAS POR ANTIGÜEDAD (>30 DÍAS)" >> "$OUTPUT_FILE"
fi
echo " Ejecutado por Cron el: $(date +"%Y-%m-%d %H:%M:%S")" >> "$OUTPUT_FILE"
echo "=====================================================================" >> "$OUTPUT_FILE"

# Clonación automática temporal
if [ -d "$REPO_PATH" ]; then
    rm -rf "$REPO_PATH"
fi

$GIT_CMD clone "$REPO_URL" "$REPO_PATH" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "[$(date +"%Y-%m-%d %H:%M:%S")] ERROR CRÍTICO: No se pudo clonar el repositorio." >> "$OUTPUT_FILE"
    exit 1
fi

cd "$REPO_PATH" || exit 1

# Función para obtener los días de antigüedad
get_branch_days_old() {
    local branch_name="$1"
    local primer_commit
    
    local main_branch
    main_branch=$($GIT_CMD symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@refs/remotes/@@')
    [ -z "$main_branch" ] && main_branch="origin/main"

    primer_commit=$($GIT_CMD rev-list --reverse "$main_branch".."$branch_name" | head -n 1)
    
    if [ -z "$primer_commit" ]; then
        primer_commit=$($GIT_CMD rev-parse "$branch_name")
    fi

    local commit_timestamp
    commit_timestamp=$($GIT_CMD show --no-patch --format=%ct "$primer_commit")
    local current_timestamp
    current_timestamp=$(date +%s)
    
    echo $(( (current_timestamp - commit_timestamp) / 86400 ))
}

# Variable de control para saber si se encontraron ramas en esta ejecución
ramas_detectadas=0

# Listado seguro de ramas
$GIT_CMD for-each-ref --format='%(refname:short)' refs/remotes/origin/ | grep -viE 'HEAD|main|master|develop' | while read -r branch; do
    
    if [ -z "$branch" ] || [ "$branch" = "origin" ]; then
        continue
    fi

    days_difference=$(get_branch_days_old "$branch")
    
    if [ "$days_difference" -gt 30 ]; then
        ramas_detectadas=$((ramas_detectadas + 1))
        clean_branch_name="${branch#origin/}"
        fecha_registro=$(date +"%Y-%m-%d %H:%M:%S")
        
        if [ "$DRY_RUN" = true ]; then
            echo "[$fecha_registro] DETECTADA (POR BORRAR): $clean_branch_name | Antigüedad: $days_difference días" >> "$OUTPUT_FILE"
        else
            $GIT_CMD push origin --delete "$clean_branch_name" > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                echo "[$fecha_registro] BORRADA: $clean_branch_name | Antigüedad: $days_difference días" >> "$OUTPUT_FILE"
            else
                echo "[$fecha_registro] ERROR AL BORRAR: $clean_branch_name | Antigüedad: $days_difference días" >> "$OUTPUT_FILE"
            fi
        fi
    fi
done

# Limpieza de la carpeta temporal
cd ..
rm -rf "$REPO_PATH"

echo "=====================================================================" >> "$OUTPUT_FILE"
