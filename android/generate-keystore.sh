#!/bin/bash
# Bash script to generate Android keystore with predefined configuration
# Usage: ./generate-keystore.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/keystore-config.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: keystore-config.env not found!${NC}"
    echo -e "${YELLOW}Please create keystore-config.env file first.${NC}"
    exit 1
fi

# Load configuration
source "$CONFIG_FILE"

# Validate required parameters
REQUIRED_VARS=("KEYSTORE_FILE" "KEY_ALIAS" "KEYSTORE_PASSWORD" "KEY_PASSWORD" 
               "DN_NAME" "DN_OU" "DN_O" "DN_L" "DN_ST" "DN_C" "VALIDITY")

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: Missing required parameter: $var${NC}"
        exit 1
    fi
done

# Build Distinguished Name (DN)
DN="CN=$DN_NAME, OU=$DN_OU, O=$DN_O, L=$DN_L, ST=$DN_ST, C=$DN_C"

# Check if keystore already exists
KEYSTORE_PATH="$SCRIPT_DIR/$KEYSTORE_FILE"
if [ -f "$KEYSTORE_PATH" ]; then
    echo -e "${YELLOW}Warning: Keystore file already exists: $KEYSTORE_PATH${NC}"
    read -p "Do you want to overwrite it? (yes/no): " response
    if [ "$response" != "yes" ]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        exit 0
    fi
    rm -f "$KEYSTORE_PATH"
fi

echo -e "${GREEN}Generating keystore...${NC}"
echo -e "${CYAN}Keystore file: $KEYSTORE_FILE${NC}"
echo -e "${CYAN}Key alias: $KEY_ALIAS${NC}"
echo -e "${CYAN}DN: $DN${NC}"

# Generate keystore
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY" \
    -dname "$DN" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD"

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}Keystore generated successfully!${NC}"
    echo -e "${CYAN}Location: $KEYSTORE_PATH${NC}"
    
    # Verify keystore
    echo -e "\n${YELLOW}Verifying keystore...${NC}"
    keytool -list -v -keystore "$KEYSTORE_PATH" -storepass "$KEYSTORE_PASSWORD"
    
    echo -e "\n${GREEN}=== Next Steps ===${NC}"
    echo -e "${YELLOW}1. Add GitHub Secrets (Settings > Secrets and variables > Actions):${NC}"
    echo -e "   ${NC}- KEYSTORE_PASSWORD: $KEYSTORE_PASSWORD${NC}"
    echo -e "   ${NC}- KEY_PASSWORD: $KEY_PASSWORD${NC}"
    echo -e "   ${NC}- KEY_ALIAS: $KEY_ALIAS${NC}"
    echo -e "\n${YELLOW}2. Generate KEYSTORE_BASE64 secret:${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "   ${NC}Run: base64 -i $KEYSTORE_PATH | pbcopy${NC}"
    else
        echo -e "   ${NC}Run: base64 $KEYSTORE_PATH | xclip -selection clipboard${NC}"
    fi
    echo -e "   ${NC}Then paste from clipboard to GitHub Secret${NC}"
    echo -e "\n${RED}3. IMPORTANT: Keep keystore-config.env and $KEYSTORE_FILE secure!${NC}"
    echo -e "   ${RED}These files should NEVER be committed to Git.${NC}"
else
    echo -e "\n${RED}Error: Keystore generation failed!${NC}"
    exit 1
fi
