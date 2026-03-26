# =====================================================
# FormataAI Backend — Deploy no AWS EC2
# =====================================================
# Pré-requisitos:
#   1. AWS CLI configurado (aws configure)
#   2. Chave SSH existente na AWS (KeyName abaixo)
#   3. Domínio apontando para o IP do EC2 (opcional, para HTTPS)
#
# Uso:
#   chmod +x deploy-ec2.sh
#   ./deploy-ec2.sh
# =====================================================

#!/usr/bin/env bash
set -euo pipefail

# ─── Variáveis (edite conforme necessário) ───────────
AWS_REGION="us-east-1"
INSTANCE_TYPE="t3.small"         # 2 vCPU, 2GB RAM — suficiente para o app
AMI_ID="ami-0c02fb55956c7d316"   # Amazon Linux 2023 (us-east-1) — verifique a mais recente
KEY_NAME="formataai-key"         # Nome da key pair na AWS
SECURITY_GROUP_NAME="formataai-sg"
INSTANCE_NAME="FormataAI-Backend"

echo "🚀 Iniciando deploy do FormataAI Backend na AWS EC2..."

# ─── 1. Criar Security Group ─────────────────────────
echo "📦 Criando Security Group..."
SG_ID=$(aws ec2 create-security-group \
  --group-name "$SECURITY_GROUP_NAME" \
  --description "FormataAI Backend - HTTP, HTTPS, SSH" \
  --region "$AWS_REGION" \
  --query 'GroupId' --output text 2>/dev/null || \
  aws ec2 describe-security-groups \
    --group-names "$SECURITY_GROUP_NAME" \
    --region "$AWS_REGION" \
    --query 'SecurityGroups[0].GroupId' --output text)

echo "   SG: $SG_ID"

# Regras de entrada
for PORT in 22 80 443; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port "$PORT" \
    --cidr 0.0.0.0/0 \
    --region "$AWS_REGION" 2>/dev/null || true
done

# ─── 2. User Data (script de inicialização) ──────────
USER_DATA=$(cat <<'USERDATA'
#!/bin/bash
set -e

# Atualizar sistema
dnf update -y

# Instalar Docker
dnf install -y docker
systemctl enable docker
systemctl start docker

# Instalar Docker Compose
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Instalar Git
dnf install -y git

# Criar diretório do app
mkdir -p /opt/formataai
cd /opt/formataai

# Placeholder — o código será enviado via rsync/git depois
echo "EC2 pronta para deploy do FormataAI" > /opt/formataai/ready.txt

USERDATA
)

# ─── 3. Criar instância EC2 ──────────────────────────
echo "🖥️  Criando instância EC2 ($INSTANCE_TYPE)..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --user-data "$USER_DATA" \
  --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" \
  --region "$AWS_REGION" \
  --query 'Instances[0].InstanceId' --output text)

echo "   Instance: $INSTANCE_ID"

# ─── 4. Aguardar instância ficar running ─────────────
echo "⏳ Aguardando instância iniciar..."
aws ec2 wait instance-running \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION"

# Obter IP público
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$AWS_REGION" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo ""
echo "✅ EC2 criada com sucesso!"
echo "══════════════════════════════════════════════"
echo "   Instance ID:  $INSTANCE_ID"
echo "   IP Público:   $PUBLIC_IP"
echo "   SSH:          ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
echo "══════════════════════════════════════════════"
echo ""
echo "📋 Próximos passos:"
echo ""
echo "   1. Enviar o código para a EC2:"
echo "      rsync -avz -e 'ssh -i ${KEY_NAME}.pem' \\"
echo "        --exclude node_modules --exclude .git --exclude coverage \\"
echo "        ./ ec2-user@${PUBLIC_IP}:/opt/formataai/"
echo ""
echo "   2. Conectar via SSH e configurar o .env:"
echo "      ssh -i ${KEY_NAME}.pem ec2-user@${PUBLIC_IP}"
echo "      cd /opt/formataai"
echo "      cp .env.example .env"
echo "      nano .env"
echo ""
echo "   3. Subir os containers:"
echo "      sudo docker-compose up -d"
echo ""
echo "   4. Rodar as migrations:"
echo "      sudo docker-compose exec app npx prisma migrate deploy"
echo ""
echo "   5. (Opcional) Configurar HTTPS:"
echo "      sudo docker-compose run --rm certbot certonly \\"
echo "        --webroot -w /var/lib/letsencrypt -d SEU_DOMINIO"
echo "      # Depois descomente o bloco SSL no nginx.conf"
echo "      sudo docker-compose restart nginx"
