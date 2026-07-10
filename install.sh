#!/bin/bash
# ZipLoot Linux/macOS 1-Click Serverless URL Shortener Setup
echo "=============================================="
echo "⚡ ZipLoot - Linux/macOS Auto-Installer ⚡"
echo "=============================================="

PAT=""
while [ -z "$PAT" ]; do
    read -p "[INPUT] Enter your GitHub Personal Access Token (PAT): " PAT
done

echo -e "\n[INFO] Connecting to GitHub...\n"

# 1. Fetch Username
USER_JSON=$(curl -s -H "Authorization: token $PAT" https://api.github.com/user)
USERNAME=$(echo "$USER_JSON" | grep -oP '"login": "\K[^"]+')

if [ -z "$USERNAME" ]; then
    echo "❌ [ERROR] Invalid GitHub Token. Please check your token and try again."
    exit 1
fi

REPO_NAME="$USERNAME.github.io"
echo "✅ Logged in as: $USERNAME"
echo "✅ Repository to create: $REPO_NAME"

# 2. Create Repository
echo "⚙️ Creating repository..."
curl -s -X POST -H "Authorization: token $PAT" \
     -H "Content-Type: application/json" \
     -d "{\"name\":\"$REPO_NAME\",\"description\":\"Serverless URL Shortener\",\"private\":false}" \
     https://api.github.com/user/repos > /dev/null

# Function to upload file
upload_file() {
    FILE=$1
    CONTENT=$(curl -sL "https://raw.githubusercontent.com/Ziploot/unlimited-url-shortener/main/$FILE")
    if [ "$FILE" = "admin.html" ]; then
        CONTENT="${CONTENT//let owner = \"Ziploot\";/let owner = \"$USERNAME\"}"
        CONTENT="${CONTENT//let repo = \"unlimited-url-shortener\";/let repo = \"$REPO_NAME\"}"
    fi
    if [ "$FILE" = "404.html" ]; then
        CONTENT="${CONTENT//const owner = window.location.hostname.split('.')[0];/const owner = \"$USERNAME\"}"
        CONTENT="${CONTENT//const repo  = owner + '.github.io';/const repo = \"$REPO_NAME\"}"
    fi
    BASE64_CONTENT=$(echo -n "$CONTENT" | base64 | tr -d '\n')
    
    # Get SHA if exists
    SHA=$(curl -s -H "Authorization: token $PAT" "https://api.github.com/repos/$USERNAME/$REPO_NAME/contents/$FILE" | grep -oP '"sha": "\K[^"]+')
    
    PAYLOAD="{\"message\":\"Deploy $FILE via ZipLoot\",\"content\":\"$BASE64_CONTENT\""
    if [ ! -z "$SHA" ]; then
        PAYLOAD="$PAYLOAD,\"sha\":\"$SHA\""
    fi
    PAYLOAD="$PAYLOAD}"
    
    curl -s -X PUT -H "Authorization: token $PAT" \
         -H "Content-Type: application/json" \
         -d "$PAYLOAD" \
         "https://api.github.com/repos/$USERNAME/$REPO_NAME/contents/$FILE" > /dev/null
         
    echo "✅ Uploaded $FILE"
}

# 3. Upload files
echo "⚙️ Uploading files..."
upload_file "index.html"
upload_file "404.html"
upload_file "admin.html"
upload_file "redirects.json"
upload_file "README.md"

# 4. Activate Pages
echo "⚙️ Activating GitHub Pages..."
curl -s -X POST -H "Authorization: token $PAT" \
     -H "Accept: application/vnd.github.v3+json" \
     -H "Content-Type: application/json" \
     -d '{"source":{"branch":"main","path":"/"}}' \
     "https://api.github.com/repos/$USERNAME/$REPO_NAME/pages" > /dev/null

# 5. Wait for Pages deployment to be live
echo -n "⚙️ Waiting for GitHub Pages to build and deploy your site (this takes 20-40s)..."
for i in {1..15}; do
    echo -n "."
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$REPO_NAME/admin.html")
    if [ "$STATUS" -eq 200 ] || [ "$STATUS" -eq 301 ] || [ "$STATUS" -eq 302 ]; then
        break
    fi
    sleep 5
done
echo ""

echo -e "\n========================================================"
echo "🎉 Setup Completed! Your Link Shortener is active!"
echo "Redirection Site: https://$REPO_NAME"
echo "Admin Dashboard:  https://$REPO_NAME/admin.html"
echo "========================================================"
