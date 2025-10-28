#!/bin/bash
# Script para hacer ejecutables los scripts de deploy

chmod +x scripts/deploy-manager.sh
chmod +x scripts/quick-deploy.sh

echo "✅ Scripts configurados:"
echo "  📋 deploy-manager.sh - Script completo con menú interactivo"
echo "  ⚡ quick-deploy.sh - Script rápido para uso diario"
echo ""
echo "Uso:"
echo "  ./scripts/deploy-manager.sh    # Menú completo"
echo "  ./scripts/quick-deploy.sh backend  # Actualizar backend rápido"