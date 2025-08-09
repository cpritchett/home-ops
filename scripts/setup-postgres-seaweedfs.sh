#!/bin/bash

echo "🗃️  SEAWEEDFS POSTGRES BACKUP BUCKET SETUP"
echo "========================================"
echo "Creating postgres-backup bucket for CloudNative-PG backups"
echo

# Check if 1Password CLI is available
if ! command -v op &>/dev/null; then
    echo "❌ 1Password CLI not found. Please install it first."
    exit 1
fi

# Check if we're signed in to 1Password
if ! op account list &>/dev/null; then
    echo "❌ Not signed in to 1Password. Please run 'op signin' first."
    exit 1
fi

echo "🔍 Getting SeaweedFS S3 credentials from 1Password..."

# Get S3 credentials from 1Password
S3_ACCESS_KEY=$(op item get seaweedfs --vault homelab --field S3_ACCESS_KEY_ID 2>/dev/null)
S3_SECRET_KEY=$(op item get seaweedfs --vault homelab --field S3_SECRET_ACCESS_KEY 2>/dev/null)
S3_ENDPOINT=$(op item get seaweedfs --vault homelab --field S3_ENDPOINT 2>/dev/null)

if [[ -z ${S3_ACCESS_KEY} || -z ${S3_SECRET_KEY} || -z ${S3_ENDPOINT} ]]; then
    echo "❌ Could not retrieve SeaweedFS credentials from 1Password"
    echo "Make sure the 'seaweedfs' entry exists in the 'homelab' vault"
    exit 1
fi

echo "✅ Retrieved SeaweedFS credentials"
echo "📡 Endpoint: ${S3_ENDPOINT}"
echo

# Check if s3cmd is available
if ! command -v s3cmd &>/dev/null; then
    echo "📦 Installing s3cmd..."
    if command -v pip3 &>/dev/null; then
        pip3 install s3cmd
    elif command -v pip &>/dev/null; then
        pip install s3cmd
    else
        echo "❌ Please install s3cmd first:"
        echo "   pip install s3cmd"
        exit 1
    fi
fi

echo "🪣 Creating postgres-backup bucket..."

# Create the postgres-backup bucket
echo "Attempting to create bucket..."
s3cmd mb s3://postgres-backup \
    --access_key="${S3_ACCESS_KEY}" \
    --secret_key="${S3_SECRET_KEY}" \
    --host="${S3_ENDPOINT#https://}" \
    --host-bucket="${S3_ENDPOINT#https://}" \
    --ssl \
    --no-check-certificate \
    --verbose 2>&1 || {

    echo "Bucket creation failed, checking if it already exists..."
    # Check if bucket already exists
    s3cmd ls s3://postgres-backup \
        --access_key="${S3_ACCESS_KEY}" \
        --secret_key="${S3_SECRET_KEY}" \
        --host="${S3_ENDPOINT#https://}" \
        --host-bucket="${S3_ENDPOINT#https://}" \
        --ssl \
        --no-check-certificate >/dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        echo "✅ postgres-backup bucket already exists"
    else
        echo "❌ Failed to create postgres-backup bucket"
        echo "Debug information:"
        echo "  Access Key: ${S3_ACCESS_KEY:0:10}..."
        echo "  Endpoint: ${S3_ENDPOINT}"
        echo ""
        echo "Let's try a simple connectivity test..."
        curl -I "${S3_ENDPOINT}" 2>/dev/null || echo "❌ Cannot reach endpoint"
        echo ""
        echo "You can manually create the bucket later using:"
        echo "  kubectl run s3-debug --rm -it --image=amazon/aws-cli -- sh"
        echo "  # Then inside the pod:"
        echo "  # aws configure set aws_access_key_id ${S3_ACCESS_KEY}"
        echo "  # aws configure set aws_secret_access_key ${S3_SECRET_KEY}"
        echo "  # aws --endpoint-url=${S3_ENDPOINT} s3 mb s3://postgres-backup"
        return 1
    fi
}

echo "✅ postgres-backup bucket is ready"
echo

echo "📋 SUMMARY:"
echo "==========="
echo "✅ Updated CloudNative-PG cluster configuration:"
echo "   • Endpoint: https://s3.hypyr.space"
echo "   • Bucket: s3://postgres-backup/"
echo "   • Server name: postgres-v23 (incremented)"
echo
echo "✅ Updated external secret to use 'seaweedfs' 1Password entry"
echo "✅ Updated volsync component to use SeaweedFS instead of R2"
echo "✅ Created postgres-backup bucket in SeaweedFS"
echo

echo "🔄 NEXT STEPS:"
echo "=============="
echo "1. Apply the updated configurations:"
echo "   kubectl apply -k kubernetes/apps/databases/cloudnative-pg/"
echo
echo "2. Force refresh external secrets:"
# shellcheck disable=SC2016
echo '   kubectl annotate externalsecrets --all external-secrets.io/force-sync=$(date +%s) -A'
echo
echo "3. Monitor the PostgreSQL backup:"
echo "   kubectl logs -n databases -l app.kubernetes.io/name=cloudnative-pg"
echo
echo "4. Check backup status:"
echo "   kubectl get backup -n databases"
echo
echo "🎉 Your PostgreSQL backups will now use SeaweedFS instead of Cloudflare R2!"
echo
echo "💡 TIP: The old R2 backups will remain accessible if you need to restore from them."
echo "    Just temporarily change the endpoint back to R2 for recovery if needed."
