#!/bin/bash

# Configuración
USERNAME="polankoak2"
REPOSITORY="prog2_tarea2"
OUTPUT_FILE="/Users/polankoak/Documents/Github/branches.txt"

# Función para obtener la fecha de creación de una rama
get_branch_creation_date() {
    branch_name="$1"
    git show --no-patch --format=%ci $(git rev-list -1 $branch_name) | awk '{print $1}'
}

# Función para calcular la diferencia en días entre dos fechas
calculate_days_difference() {
    start_date="$1"
    end_date="$2"
    echo $(( ( $(date -ud "$end_date" +'%s') - $(date -ud "$start_date" +'%s') ) / 60 / 60 / 24 ))
}

# GitHub
echo "Branches en GitHub creadas hace más de 30 días:" >> "$OUTPUT_FILE"
for branch in $(git ls-remote --heads https://$USERNAME@github.com/$USERNAME/$REPOSITORY.git | awk -F'/' '{print $NF}'); do
    creation_date=$(get_branch_creation_date $branch)
    days_difference=$(calculate_days_difference $creation_date "$(date +'%Y-%m-%d')")
    
    if [ $days_difference -gt 30 ]; then
        echo "$branch ($days_difference días)" >> "$OUTPUT_FILE"
    fi
done

echo "Proceso completado. Las branches creadas hace más de 30 días se han listado en $OUTPUT_FILE"
