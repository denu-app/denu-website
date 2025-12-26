# Denu Website

Static marketing website for Denu platform, containing landing pages, legal documents, and marketing content.

## Overview

This is a standalone static website separated from the Aglaea Flutter application. It serves:
- Landing page (index.html)
- About page
- Contact page
- Terms of Service
- Privacy Policy
- Development information

## Architecture

- **Technology**: Static HTML/CSS/JS served by Nginx
- **Domain**: `denu.dev`, `www.denu.dev`
- **Deployment**: Kubernetes (apps-denu-dev namespace)
- **Container Registry**: GitHub Container Registry (GHCR)

## Structure

```
denu-website/
├── index.html          # Landing page
├── about.html          # About page
├── contact.html        # Contact page
├── terms.html          # Terms of Service
├── privacy.html        # Privacy Policy
├── dev.html            # Development info
├── css/
│   └── style.css       # Main stylesheet
├── js/
│   ├── environment-redirect.js
│   ├── language-manager.js
│   ├── partials-loader.js
│   └── ...
├── partials/
│   ├── navbar.html
│   ├── footer.html
│   └── drawer.html
├── Dockerfile          # Nginx-based container
├── nginx.conf          # Nginx configuration
└── .github/
    └── workflows/
        └── build-and-publish.yml
```

## Development

### Local Testing

```bash
# Serve locally with any static server
python3 -m http.server 8080

# Or use nginx directly
docker build -t denu-website:local .
docker run -p 8080:8080 denu-website:local
```

### Building Docker Image

```bash
docker build -t denu-website:latest .
```

## Deployment

Deployment is automated via GitHub Actions:
- **master branch** → `ghcr.io/denu-app/denu-website:latest` → dev environment
- **production branch** → `ghcr.io/denu-app/denu-website:latest-prod` → production environment

## Routing

The website is configured to:
- Serve static pages at root paths (/, /about, /contact, etc.)
- Redirect to Aglaea Flutter app at `app.denu.dev` for application routes
- Work with the environment-aware redirect system for proper Flutter integration

## Maintenance

To update content:
1. Edit HTML/CSS/JS files
2. Test locally
3. Commit and push to master branch
4. GitHub Actions will build and deploy automatically

## Related Projects

- **Aglaea**: Flutter application at `app.denu.dev`
- **Plutus**: Backend API at `api.denu.dev`
- **denu-infrastructure**: Kubernetes and infrastructure configuration
