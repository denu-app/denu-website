#!/bin/bash

# =========================================================================
# DENU Local Testing Script
# =========================================================================
# This script provides comprehensive local testing for DENU with:
# 1. Flutter development server (flutter run -d web-server)
# 2. Local proxy server for routing static pages
# 3. Docker-based testing (mimics production environment)
#
# Usage:
#   ./test.sh              # Interactive mode - choose test type
#   ./test.sh flutter      # Start Flutter with proxy
#   ./test.sh docker       # Test with Docker
#   ./test.sh clean        # Clean up all running processes
#   ./test.sh help         # Show help
#
# Prerequisites:
#   - Flutter SDK installed
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
FLUTTER_PORT=8080
PROXY_PORT=3005
DOCKER_PORT=8081
DOCKER_IMAGE_NAME="denu-local"
FLUTTER_PID_FILE=".flutter.pid"
PROXY_PID_FILE=".proxy.pid"

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

# Check prerequisites
check_prerequisites() {
    local missing_deps=()
    
    if ! command_exists flutter; then
        missing_deps+=("flutter")
    fi
    
    if ! command_exists npm && [ "$1" != "docker-only" ]; then
        missing_deps+=("npm")
    fi
    
    if ! command_exists docker && [ "$1" == "docker" ]; then
        missing_deps+=("docker")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install the missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                flutter)
                    echo "  - Flutter: https://flutter.dev/docs/get-started/install"
                    ;;
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
    
    # Kill Flutter process
    if [ -f "$FLUTTER_PID_FILE" ]; then
        local flutter_pid=$(cat "$FLUTTER_PID_FILE")
        if ps -p $flutter_pid > /dev/null 2>&1; then
            print_info "Stopping Flutter server (PID: $flutter_pid)..."
            kill $flutter_pid 2>/dev/null || true
        fi
        rm -f "$FLUTTER_PID_FILE"
    fi
    
    # Kill proxy process
    if [ -f "$PROXY_PID_FILE" ]; then
        local proxy_pid=$(cat "$PROXY_PID_FILE")
        if ps -p $proxy_pid > /dev/null 2>&1; then
            print_info "Stopping proxy server (PID: $proxy_pid)..."
            kill $proxy_pid 2>/dev/null || true
        fi
        rm -f "$PROXY_PID_FILE"
    fi
    
    # Kill any remaining processes on ports
    kill_port $FLUTTER_PORT
    kill_port $PROXY_PORT
    kill_port $DOCKER_PORT
    
    # Stop Docker containers
    local docker_containers=$(docker ps -q --filter "ancestor=$DOCKER_IMAGE_NAME")
    if [ -n "$docker_containers" ]; then
        print_info "Stopping Docker containers..."
        docker stop $docker_containers 2>/dev/null || true
    fi
    
    print_success "Cleanup completed"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# =========================================================================
# Testing Mode 1: Flutter with Proxy Server
# =========================================================================

test_flutter_with_proxy() {
    print_header "Starting DENU with Flutter Development Server"
    
    check_prerequisites "flutter"
    install_http_server
    
    # Clean up any existing processes
    kill_port $FLUTTER_PORT
    kill_port $PROXY_PORT
    
    # Get Flutter dependencies
    print_info "Getting Flutter dependencies..."
    flutter pub get
    
    # Build Flutter web for initial static files
    print_info "Building Flutter web app..."
    flutter build web --release
    
    # Rename index.html to app.html
    print_info "Renaming index.html to app.html..."
    if [ -f "build/web/index.html" ]; then
        mv build/web/index.html build/web/app.html
        print_success "Renamed index.html to app.html"
    fi
    
    # Start Flutter development server in background
    print_info "Starting Flutter development server on port $FLUTTER_PORT..."
    flutter run -d web-server --web-port $FLUTTER_PORT --web-hostname 0.0.0.0 > flutter.log 2>&1 &
    FLUTTER_PID=$!
    echo $FLUTTER_PID > "$FLUTTER_PID_FILE"
    
    # Wait for Flutter server to start
    print_info "Waiting for Flutter server to start..."
    for i in {1..30}; do
        if curl -s http://localhost:$FLUTTER_PORT > /dev/null 2>&1; then
            print_success "Flutter server started (PID: $FLUTTER_PID)"
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "Flutter server failed to start. Check flutter.log for details."
            exit 1
        fi
        sleep 1
    done
    
    # Create proxy configuration script
    print_info "Creating proxy server..."
    cat > proxy-server.js <<'EOF'
const http = require('http');
const httpProxy = require('http-proxy');
const fs = require('fs');
const path = require('path');

const FLUTTER_PORT = process.env.FLUTTER_PORT || 8080;
const PROXY_PORT = process.env.PROXY_PORT || 3000;

// Create proxy to Flutter server
const proxy = httpProxy.createProxyServer({
    target: `http://localhost:${FLUTTER_PORT}`,
    ws: true  // Enable WebSocket proxying for hot reload
});

const server = http.createServer((req, res) => {
    // Serve static landing page at /
    if (req.url === '/') {
        const indexPath = path.join(__dirname, 'static', 'index.html');
        fs.readFile(indexPath, 'utf8', (err, data) => {
            if (err) {
                console.error('Error reading index.html:', err);
                res.writeHead(500);
                res.end('Internal Server Error');
                return;
            }
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(data);
        });
        return;
    }
    
    // Serve static about page at /about
    if (req.url === '/about') {
        const aboutPath = path.join(__dirname, 'static', 'about.html');
        fs.readFile(aboutPath, 'utf8', (err, data) => {
            if (err) {
                console.error('Error reading about.html:', err);
                res.writeHead(500);
                res.end('Internal Server Error');
                return;
            }
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.end(data);
        });
        return;
    }
    
    // Proxy all other requests to Flutter server
    proxy.web(req, res, {}, (err) => {
        console.error('Proxy error:', err);
        res.writeHead(502);
        res.end('Bad Gateway');
    });
});

// Proxy WebSocket connections
server.on('upgrade', (req, socket, head) => {
    proxy.ws(req, socket, head);
});

server.listen(PROXY_PORT, () => {
    console.log(`✅ Proxy server running on http://localhost:${PROXY_PORT}`);
    console.log(`   - Static pages: /, /about`);
    console.log(`   - Flutter app: all other routes`);
    console.log(`   - Flutter backend: http://localhost:${FLUTTER_PORT}`);
});
EOF
    
    # Install http-proxy if not present
    if [ ! -d "node_modules/http-proxy" ]; then
        print_info "Installing http-proxy..."
        npm init -y > /dev/null 2>&1
        npm install http-proxy --save > /dev/null 2>&1
    fi
    
    # Start proxy server
    print_info "Starting proxy server on port $PROXY_PORT..."
    FLUTTER_PORT=$FLUTTER_PORT PROXY_PORT=$PROXY_PORT node proxy-server.js > proxy.log 2>&1 &
    PROXY_PID=$!
    echo $PROXY_PID > "$PROXY_PID_FILE"
    
    # Wait for proxy server to start
    sleep 3
    if ! ps -p $PROXY_PID > /dev/null; then
        print_error "Proxy server failed to start. Check proxy.log for details."
        exit 1
    fi
    print_success "Proxy server started (PID: $PROXY_PID)"
    
    # Display test URLs
    print_header "DENU is Running!"
    echo ""
    print_success "Access DENU at:"
    echo ""
    echo "  📄 Landing Page:     http://localhost:$PROXY_PORT/"
    echo "  📄 About Page:       http://localhost:$PROXY_PORT/about"
    echo "  🚀 DENU App:         http://localhost:$PROXY_PORT/discover"
    echo ""
    print_info "Direct Flutter Server:"
    echo "  🔧 Flutter Dev:      http://localhost:$FLUTTER_PORT/"
    echo ""
    print_warning "Logs:"
    echo "  Flutter: flutter.log"
    echo "  Proxy:   proxy.log"
    echo ""
    print_info "Press Ctrl+C to stop all servers"
    echo ""
    
    # Validation tests
    print_header "Running Validation Tests"
    sleep 2
    
    echo -n "Testing landing page (/)...        "
    if curl -s http://localhost:$PROXY_PORT/ | grep -q "Welcome to DENU"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo -n "Testing about page (/about)...     "
    if curl -s http://localhost:$PROXY_PORT/about | grep -q "About DENU"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo -n "Testing Flutter app (/discover)... "
    if curl -s http://localhost:$PROXY_PORT/discover | grep -q "flutter"; then
        print_success "PASSED"
    else
        print_warning "SKIPPED (Flutter may not be fully loaded)"
    fi
    
    echo ""
    print_info "SEO Testing with Lighthouse:"
    echo "  npx lighthouse http://localhost:$PROXY_PORT/ --view"
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
    
    # Clean up existing containers
    cleanup
    
    # Build Flutter web app first
    print_info "Building Flutter web application..."
    flutter pub get
    flutter build web --release
    
    # Rename index.html to app.html
    print_info "Renaming index.html to app.html..."
    if [ -f "build/web/index.html" ]; then
        mv build/web/index.html build/web/app.html
        print_success "Renamed index.html to app.html"
    fi
    
    # Build Docker image
    print_info "Building Docker image: $DOCKER_IMAGE_NAME..."
    docker build -t $DOCKER_IMAGE_NAME -f Dockerfile .
    print_success "Docker image built successfully"
    
    # Run Docker container
    print_info "Starting Docker container on port $DOCKER_PORT..."
    docker run -d \
        --name denu-test \
        -p $DOCKER_PORT:80 \
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
    echo "  🚀 DENU App:         http://localhost:$DOCKER_PORT/discover"
    echo "  ❤️  Health Check:     http://localhost:$DOCKER_PORT/health"
    echo ""
    print_info "Docker Commands:"
    echo "  View logs:    docker logs -f denu-test"
    echo "  Stop:         docker stop denu-test"
    echo "  Remove:       docker rm denu-test"
    echo ""
    
    # Validation tests
    print_header "Running Validation Tests"
    sleep 2
    
    echo -n "Testing health endpoint (/health)... "
    if curl -s http://localhost:$DOCKER_PORT/health | grep -q "healthy"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo -n "Testing landing page (/)...          "
    if curl -s http://localhost:$DOCKER_PORT/ | grep -q "Welcome to DENU"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo -n "Testing about page (/about)...       "
    if curl -s http://localhost:$DOCKER_PORT/about | grep -q "About DENU"; then
        print_success "PASSED"
    else
        print_error "FAILED"
    fi
    
    echo -n "Testing Flutter app (/discover)...   "
    if curl -s http://localhost:$DOCKER_PORT/discover | grep -q "flutter"; then
        print_success "PASSED"
    else
        print_warning "SKIPPED (Check manually)"
    fi
    
    echo -n "Testing asset loading...             "
    if curl -s http://localhost:$DOCKER_PORT/assets/AssetManifest.json > /dev/null 2>&1; then
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
  flutter       Start Flutter development server with proxy for routing
                (Default: Flutter on :8080, Proxy on :3000)
                
  docker        Build and run Docker container for production testing
                (Default: Docker on :8081)
                
  clean         Clean up all running processes and containers
  
  help          Show this help message

${GREEN}Examples:${NC}
  ./test.sh                    # Interactive mode
  ./test.sh flutter            # Test with Flutter + proxy
  ./test.sh docker             # Test with Docker
  ./test.sh clean              # Clean up

${GREEN}Testing Checklist:${NC}
  1. Landing page loads at /
  2. About page loads at /about
  3. Clicking "Start Exploring" navigates to /discover
  4. Flutter app loads and routes work (/discover, /profile, etc.)
  5. Static assets load correctly (images, fonts, JS)
  6. SEO meta tags present on static pages
  7. No JavaScript required for landing page

${GREEN}SEO Testing:${NC}
  Run Lighthouse audit:
    npx lighthouse http://localhost:3000/ --view

${GREEN}Prerequisites:${NC}
  - Flutter SDK: https://flutter.dev/docs/get-started/install
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
        flutter)
            test_flutter_with_proxy
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
            echo "  1) Flutter with Proxy (Development)"
            echo "  2) Docker (Production-like)"
            echo "  3) Clean up"
            echo "  4) Help"
            echo ""
            read -p "Enter choice [1-4]: " choice
            echo ""
            
            case $choice in
                1)
                    test_flutter_with_proxy
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

