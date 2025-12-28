#!/bin/bash

# =========================================================================
# DENU Local Testing Script
# =========================================================================
# This script provides local testing for the DENU Static Website with:
# 1. Local development server (http-server)
# 2. Docker-based testing (mimics production environment)
#
# Usage:
#   ./test.sh              # Interactive mode - choose test type
#   ./test.sh local        # Start local development server
#   ./test.sh docker       # Test with Docker
#   ./test.sh clean        # Clean up all running processes
#   ./test.sh help         # Show help
#
# Prerequisites:
#   - Docker installed (for Docker testing)
#   - Node.js and npm installed (for http-server)

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOCAL_PORT=3000
DOCKER_PORT=8081
DOCKER_IMAGE_NAME="denu-local"
LOCAL_PID_FILE=".local.pid"

# =========================================================================
# Helper Functions
# =========================================================================

print_header() {
    echo -e "${BLUE}==========================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if docker is available and responsive
docker_available() {
    if ! command_exists docker; then
        return 1
    fi
    # Quick check if daemon is responsive
    docker info >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    local missing_deps=()
    
    if ! command_exists npm; then
        missing_deps+=("npm")
    fi
    
    if [ "$1" == "docker" ]; then
        if ! command_exists docker; then
            missing_deps+=("docker")
        fi
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install the missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                npm)
                    echo "  - Node.js/npm: https://nodejs.org/"
                    ;;
                docker)
                    echo "  - Docker: https://docs.docker.com/get-docker/"
                    ;;
            esac
        done
        exit 1
    fi
}

# Install http-server if not present
install_http_server() {
    if ! command_exists http-server; then
        print_info "Installing http-server globally..."
        npm install -g http-server
        print_success "http-server installed"
    fi
}

# Kill process on port
kill_port() {
    local port=$1
    local pid=$(lsof -ti:$port)
    if [ -n "$pid" ]; then
        print_warning "Killing process on port $port (PID: $pid)"
        kill -9 $pid 2>/dev/null || true
        sleep 1
    fi
}

# Clean up all processes
cleanup() {
    print_header "Cleaning Up"
    
    # Kill local server process
    if [ -f "$LOCAL_PID_FILE" ]; then
        local local_pid=$(cat "$LOCAL_PID_FILE")
        if ps -p $local_pid > /dev/null 2>&1; then
            print_info "Stopping local server (PID: $local_pid)..."
            kill $local_pid 2>/dev/null || true
        fi
        rm -f "$LOCAL_PID_FILE"
    fi
    
    # Kill any remaining processes on ports
    kill_port $LOCAL_PORT
    kill_port $DOCKER_PORT
    
    # Stop Docker containers (only if docker is available)
    if docker_available; then
        local docker_containers=$(docker ps -q --filter "ancestor=$DOCKER_IMAGE_NAME")
        if [ -n "$docker_containers" ]; then
            print_info "Stopping Docker containers..."
            docker stop $docker_containers 2>/dev/null || true
        fi
    else
        print_warning "Docker daemon not responsive, skipping container cleanup"
    fi
    
    print_success "Cleanup completed"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# =========================================================================
# Testing Mode 1: Flutter with Proxy Server
# =========================================================================

test_local() {
    print_header "Starting DENU Local Development Server"
    
    check_prerequisites
    install_http_server
    
    # Clean up any existing processes
    kill_port $LOCAL_PORT
    
    # Start http-server in background
    print_info "Starting http-server on port $LOCAL_PORT..."
    http-server . -p $LOCAL_PORT > local.log 2>&1 &
    LOCAL_PID=$!
    echo $LOCAL_PID > "$LOCAL_PID_FILE"
    
    # Wait for server to start
    print_info "Waiting for server to start..."
    for i in {1..10}; do
        if curl -s http://localhost:$LOCAL_PORT > /dev/null 2>&1; then
            print_success "Local server started (PID: $LOCAL_PID)"
            break
        fi
        if [ $i -eq 10 ]; then
            print_error "Local server failed to start. Check local.log for details."
            exit 1
        fi
        sleep 1
    done
    
    # Display test URLs
    print_header "DENU is Running!"
    echo ""
    print_success "Access DENU at:"
    echo ""
    echo "  📄 Landing Page:     http://localhost:$LOCAL_PORT/"
    echo "  📄 About Page:       http://localhost:$LOCAL_PORT/about.html"
    echo "  📄 Contact Page:     http://localhost:$LOCAL_PORT/contact.html"
    echo ""
    print_warning "Logs:"
    echo "  Server: local.log"
    echo ""
    print_info "Press Ctrl+C to stop the server"
    echo ""
    
    # Validation tests
    print_header "Running Validation Tests"
    sleep 2
    
    echo -n "Testing landing page (/)...        "
    if curl -s http://localhost:$LOCAL_PORT/ | grep -q "DENU"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo -n "Testing about page (/about.html)... "
    if curl -s http://localhost:$LOCAL_PORT/about.html | grep -q "About"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo ""
    print_info "SEO Testing with Lighthouse:"
    echo "  npx lighthouse http://localhost:$LOCAL_PORT/ --view"
    echo ""
    
    # Keep script running
    wait
}

# =========================================================================
# Testing Mode 2: Docker Build and Test
# =========================================================================

test_docker() {
    print_header "Building and Testing DENU with Docker"
    
    check_prerequisites "docker"
    
    if ! docker_available; then
        print_error "Docker daemon is not responsive. Please ensure Docker Desktop is running."
        exit 1
    fi
    
    # Clean up existing containers
    cleanup
    
    # Build Docker image
    print_info "Building Docker image: $DOCKER_IMAGE_NAME..."
    docker build -t $DOCKER_IMAGE_NAME -f Dockerfile .
    print_success "Docker image built successfully"
    
    # Run Docker container
    print_info "Starting Docker container on port $DOCKER_PORT..."
    docker run -d \
        --name denu-test \
        -p $DOCKER_PORT:8080 \
        $DOCKER_IMAGE_NAME
    
    # Wait for container to start
    print_info "Waiting for container to start..."
    for i in {1..30}; do
        if docker ps | grep -q denu-test; then
            print_success "Docker container started"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Docker container failed to start"
            docker logs denu-test
            exit 1
        fi
        sleep 1
    done
    
    # Wait for health check
    sleep 3
    
    # Display test URLs
    print_header "DENU Docker Container is Running!"
    echo ""
    print_success "Access DENU at:"
    echo ""
    echo "  📄 Landing Page:     http://localhost:$DOCKER_PORT/"
    echo "  📄 About Page:       http://localhost:$DOCKER_PORT/about"
    echo "  ❤️  Health Check:     http://localhost:$DOCKER_PORT/"
    echo ""
    print_info "Docker Commands:"
    echo "  View logs:    docker logs -f denu-test"
    echo "  Stop:         docker stop denu-test"
    echo "  Remove:       docker rm denu-test"
    echo ""
    
    # Validation tests
    print_header "Running Validation Tests"
    sleep 2
    
    echo -n "Testing landing page (/)...          "
    if curl -s http://localhost:$DOCKER_PORT/ | grep -q "DENU"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo -n "Testing about page (/about)...       "
    if curl -s http://localhost:$DOCKER_PORT/about | grep -q "About"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo ""
    print_info "Docker container is running in detached mode"
    print_warning "Remember to clean up: docker stop denu-test && docker rm denu-test"
    echo ""
}

# =========================================================================
# Show Help
# =========================================================================

show_help() {
    cat <<EOF
${BLUE}DENU Local Testing Script${NC}

${GREEN}Usage:${NC}
  ./test.sh [command]

${GREEN}Commands:${NC}
  local         Start local development server (http-server)
                (Default: :3000)
                
  docker        Build and run Docker container for production testing
                (Default: :8081)
                
  clean         Clean up all running processes and containers
  
  help          Show this help message

${GREEN}Examples:${NC}
  ./test.sh                    # Interactive mode
  ./test.sh local              # Test locally
  ./test.sh docker             # Test with Docker
  ./test.sh clean              # Clean up

${GREEN}Testing Checklist:${NC}
  1. Landing page loads at /
  2. About page loads at /about.html
  3. Contact page loads at /contact.html
  4. Static assets load correctly (images, fonts, JS)
  5. SEO meta tags present on static pages
  6. No JavaScript required for landing page content

${GREEN}SEO Testing:${NC}
  Run Lighthouse audit:
    npx lighthouse http://localhost:3000/ --view

${GREEN}Prerequisites:${NC}
  - Docker: https://docs.docker.com/get-docker/
  - Node.js/npm: https://nodejs.org/

EOF
}

# =========================================================================
# Main Script
# =========================================================================

main() {
    local command=${1:-interactive}
    
    case $command in
        local)
            test_local
            ;;
        docker)
            test_docker
            ;;
        clean)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        interactive)
            print_header "DENU Local Testing"
            echo ""
            echo "Choose testing mode:"
            echo "  1) Local Server (Development)"
            echo "  2) Docker (Production-like)"
            echo "  3) Clean up"
            echo "  4) Help"
            echo ""
            read -p "Enter choice [1-4]: " choice
            echo ""
            
            case $choice in
                1)
                    test_local
                    ;;
                2)
                    test_docker
                    ;;
                3)
                    cleanup
                    ;;
                4)
                    show_help
                    ;;
                *)
                    print_error "Invalid choice"
                    exit 1
                    ;;
            esac
            ;;
        *)
            print_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

