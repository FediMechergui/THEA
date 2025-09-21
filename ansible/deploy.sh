#!/bin/bash
# THEA Backend Deployment Script
# This script provides easy deployment commands for THEA Backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INVENTORY_FILE="inventory.ini"
PLAYBOOK_FILE="deploy.yml"
VAULT_PASSWORD_FILE=".vault_pass"

# Functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  THEA Backend Ansible Deployment${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo ""
}

print_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  deploy [environment]    Deploy to specified environment (production/staging/development)"
    echo "  update [environment]    Update services in specified environment"
    echo "  backup [environment]    Create backup of specified environment"
    echo "  status [environment]    Check status of services"
    echo "  logs [environment]      View service logs"
    echo "  encrypt-secrets         Encrypt the secrets file"
    echo "  decrypt-secrets         Decrypt the secrets file for editing"
    echo "  test-connection         Test SSH connection to servers"
    echo "  setup                   Initial setup and prerequisites check"
    echo ""
    echo "Environments:"
    echo "  production              Production environment"
    echo "  staging                 Staging environment"
    echo "  development             Development environment"
    echo "  all                     All environments"
    echo ""
    echo "Examples:"
    echo "  $0 deploy production"
    echo "  $0 update staging"
    echo "  $0 status development"
    echo "  $0 encrypt-secrets"
}

check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    # Check if ansible is installed
    if ! command -v ansible &> /dev/null; then
        echo -e "${RED}❌ Ansible is not installed. Please install Ansible first.${NC}"
        echo "Visit: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
        exit 1
    fi

    # Check if ansible-playbook is available
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}❌ ansible-playbook command not found.${NC}"
        exit 1
    fi

    # Check if inventory file exists
    if [ ! -f "$INVENTORY_FILE" ]; then
        echo -e "${RED}❌ Inventory file '$INVENTORY_FILE' not found.${NC}"
        exit 1
    fi

    # Check if playbook file exists
    if [ ! -f "$PLAYBOOK_FILE" ]; then
        echo -e "${RED}❌ Playbook file '$PLAYBOOK_FILE' not found.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
}

validate_environment() {
    local env=$1
    case $env in
        production|staging|development|all)
            return 0
            ;;
        *)
            echo -e "${RED}❌ Invalid environment: $env${NC}"
            echo "Valid environments: production, staging, development, all"
            exit 1
            ;;
    esac
}

run_ansible_command() {
    local command=$1
    local env=$2
    local extra_args=$3

    local limit_arg=""
    if [ "$env" != "all" ]; then
        limit_arg="--limit $env"
    fi

    local vault_args=""
    if [ -f "$VAULT_PASSWORD_FILE" ]; then
        vault_args="--vault-password-file $VAULT_PASSWORD_FILE"
    fi

    echo -e "${YELLOW}Running: ansible-playbook $vault_args -i $INVENTORY_FILE $limit_arg $command $extra_args${NC}"

    if ansible-playbook $vault_args -i $INVENTORY_FILE $limit_arg $command $extra_args; then
        echo -e "${GREEN}✅ Command completed successfully${NC}"
    else
        echo -e "${RED}❌ Command failed${NC}"
        exit 1
    fi
}

# Main script logic
main() {
    print_header

    case $1 in
        deploy)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Environment not specified${NC}"
                print_usage
                exit 1
            fi
            validate_environment $2
            check_prerequisites
            echo -e "${GREEN}🚀 Starting deployment to $2 environment...${NC}"
            run_ansible_command $PLAYBOOK_FILE $2
            ;;

        update)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Environment not specified${NC}"
                print_usage
                exit 1
            fi
            validate_environment $2
            check_prerequisites
            echo -e "${GREEN}🔄 Starting update for $2 environment...${NC}"
            run_ansible_command $PLAYBOOK_FILE $2 "--tags update"
            ;;

        backup)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Environment not specified${NC}"
                print_usage
                exit 1
            fi
            validate_environment $2
            check_prerequisites
            echo -e "${GREEN}💾 Starting backup for $2 environment...${NC}"
            run_ansible_command $PLAYBOOK_FILE $2 "--tags backup"
            ;;

        status)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Environment not specified${NC}"
                print_usage
                exit 1
            fi
            validate_environment $2
            check_prerequisites
            echo -e "${GREEN}📊 Checking status for $2 environment...${NC}"
            run_ansible_command $PLAYBOOK_FILE $2 "--tags status"
            ;;

        logs)
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Environment not specified${NC}"
                print_usage
                exit 1
            fi
            validate_environment $2
            check_prerequisites
            echo -e "${GREEN}📋 Fetching logs for $2 environment...${NC}"
            run_ansible_command $PLAYBOOK_FILE $2 "--tags logs"
            ;;

        encrypt-secrets)
            if [ ! -f "vars/secrets.yml" ]; then
                echo -e "${RED}❌ vars/secrets.yml not found${NC}"
                exit 1
            fi
            echo -e "${GREEN}🔒 Encrypting secrets file...${NC}"
            ansible-vault encrypt vars/secrets.yml
            echo -e "${GREEN}✅ Secrets file encrypted${NC}"
            ;;

        decrypt-secrets)
            if [ ! -f "vars/secrets.yml" ]; then
                echo -e "${RED}❌ vars/secrets.yml not found${NC}"
                exit 1
            fi
            echo -e "${GREEN}🔓 Decrypting secrets file for editing...${NC}"
            ansible-vault decrypt vars/secrets.yml
            echo -e "${YELLOW}⚠️  Remember to encrypt the file after editing!${NC}"
            echo -e "${YELLOW}   Run: $0 encrypt-secrets${NC}"
            ;;

        test-connection)
            check_prerequisites
            echo -e "${GREEN}🔗 Testing SSH connections...${NC}"
            ansible -i $INVENTORY_FILE all -m ping
            ;;

        setup)
            echo -e "${GREEN}🔧 Running initial setup...${NC}"
            check_prerequisites

            # Create vault password file if it doesn't exist
            if [ ! -f "$VAULT_PASSWORD_FILE" ]; then
                echo -e "${YELLOW}Creating vault password file...${NC}"
                echo "Enter vault password: "
                read -s vault_password
                echo $vault_password > $VAULT_PASSWORD_FILE
                chmod 600 $VAULT_PASSWORD_FILE
                echo -e "${GREEN}✅ Vault password file created${NC}"
            fi

            # Test connections
            echo -e "${GREEN}🔗 Testing connections...${NC}"
            $0 test-connection

            echo -e "${GREEN}✅ Setup completed successfully!${NC}"
            echo ""
            echo -e "${YELLOW}Next steps:${NC}"
            echo "1. Edit vars/secrets.yml with your actual secrets"
            echo "2. Run: $0 encrypt-secrets"
            echo "3. Run: $0 deploy [environment]"
            ;;

        *)
            print_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"