 # Project Restructuring Action Plan

## Overview
This document outlines the steps to restructure the FreshK project according to Django best practices. The restructuring aims to improve code organization, maintainability, and scalability.

## Phase 1: Project Structure Improvements

### Create Core App
- [ ] Create a new `core` app:
  ```bash
  python manage.py startapp core
  mv core apps/core
  ```
- [ ] Move common utilities, mixins, and base models to the core app
- [ ] Add common permissions, serializers, and general-purpose functions

### Fix URL Configuration
- [ ] Move the root `urls.py` to proper location in project settings directory
- [ ] Update imports in the project to reflect the new URL configuration location

### Create Standard Directories
- [ ] Add a global `static/` directory:
  ```bash
  mkdir -p freshk/static/{css,js,images}
  ```
- [ ] Add a `media/` directory for user uploads:
  ```bash
  mkdir -p freshk/media
  ```
- [ ] Update settings.py to reflect these changes:
  ```python
  STATIC_URL = '/static/'
  STATIC_ROOT = BASE_DIR / 'static_collected'
  STATICFILES_DIRS = [BASE_DIR / 'static']
  
  MEDIA_URL = '/media/'
  MEDIA_ROOT = BASE_DIR / 'media'
  ```

### Organize Scripts
- [ ] Create a `scripts/` directory:
  ```bash
  mkdir -p freshk/scripts
  ```
- [ ] Move utility scripts:
  ```bash
  mv generate_password_hashes.py scripts/
  mv load_seed_data.sh scripts/
  ```
- [ ] Update any references to these scripts

## Phase 2: App-Level Improvements

### Reorganize App Structure (for each app)
- [ ] Create standard app directories:
  ```bash
  for app in users products orders inventory analytics cart mobile; do
    mkdir -p freshk/apps/$app/templates/$app
    mkdir -p freshk/apps/$app/static/$app
    mkdir -p freshk/apps/$app/tests
    mkdir -p freshk/apps/$app/management/commands
  done
  ```

### Move Templates
- [ ] Move templates from global directory to app-specific directories:
  ```bash
  for app in users products orders inventory analytics cart mobile; do
    [ -d "freshk/templates/$app" ] && mv freshk/templates/$app/* freshk/apps/$app/templates/$app/
  done
  ```
- [ ] Update settings.py to include app-specific template directories

### Admin Organization
- [ ] Create admin subdirectories in each app:
  ```bash
  for app in users products orders inventory analytics cart mobile; do
    mkdir -p freshk/apps/$app/admin
    touch freshk/apps/$app/admin/__init__.py
  done
  ```
- [ ] Move admin-specific code to these subdirectories:
  ```bash
  for app in users products orders inventory analytics cart mobile; do
    [ -f "freshk/apps/$app/admin_urls.py" ] && mv freshk/apps/$app/admin_urls.py freshk/apps/$app/admin/urls.py
    [ -f "freshk/apps/$app/admin_views.py" ] && mv freshk/apps/$app/admin_views.py freshk/apps/$app/admin/views.py
  done
  ```
- [ ] Update imports and references in the project

### Add Missing App Components
- [ ] Add required files to each app:
  ```bash
  for app in users products orders inventory analytics cart mobile; do
    touch freshk/apps/$app/apps.py
    touch freshk/apps/$app/forms.py
    touch freshk/apps/$app/signals.py
    touch freshk/apps/$app/tests/__init__.py
    touch freshk/apps/$app/tests/test_models.py
    touch freshk/apps/$app/tests/test_views.py
    touch freshk/apps/$app/tests/test_serializers.py
  done
  ```
- [ ] Configure AppConfig in apps.py for each app
- [ ] Set up signals.py and connect in apps.py ready() method

## Phase 3: Settings Organization

### Split Settings
- [ ] Create a settings directory:
  ```bash
  mkdir -p freshk/freshk/settings
  touch freshk/freshk/settings/__init__.py
  ```
- [ ] Create separate settings files:
  ```bash
  touch freshk/freshk/settings/base.py
  touch freshk/freshk/settings/dev.py
  touch freshk/freshk/settings/prod.py
  touch freshk/freshk/settings/test.py
  ```
- [ ] Extract common settings to base.py
- [ ] Configure environment-specific settings in respective files
- [ ] Update manage.py and wsgi.py to use the new settings module

## Phase 4: Documentation

### Organize Documentation
- [ ] Create a docs directory:
  ```bash
  mkdir -p freshk/docs
  ```
- [ ] Move documentation files:
  ```bash
  mv freshk/API_GUIDE.md freshk/docs/
  mv freshk/PROJECT_STATUS.md freshk/docs/
  mv freshk/project_action_plan.md freshk/docs/
  mv freshk/project_implementation_report.md freshk/docs/
  mv freshk/project_improvements_summary.md freshk/docs/
  mv freshk/SEEDER_DATA.md freshk/docs/
  ```
- [ ] Create an index.md file in the docs directory

## Phase 5: Advanced Structure

### Custom Middleware
- [ ] Create a middleware package:
  ```bash
  mkdir -p freshk/freshk/middleware
  touch freshk/freshk/middleware/__init__.py
  ```
- [ ] Add any custom middleware classes needed

### Template Tags and Context Processors
- [ ] Create directories for template tags in relevant apps:
  ```bash
  for app in users products orders; do
    mkdir -p freshk/apps/$app/templatetags
    touch freshk/apps/$app/templatetags/__init__.py
  done
  ```
- [ ] Create a context processors directory:
  ```bash
  mkdir -p freshk/freshk/context_processors
  touch freshk/freshk/context_processors/__init__.py
  ```

## Phase 6: Update References

### Update Imports
- [ ] Search and update all import statements to reference the new file locations
- [ ] Update URL patterns in the main urls.py to reference the new admin URL modules

### Update Settings
- [ ] Update INSTALLED_APPS to use the AppConfig classes
- [ ] Configure template dirs to include app-specific templates

## Phase 7: Testing

### Run Tests and Fix Issues
- [ ] Run tests to verify the restructuring didn't break functionality:
  ```bash
  python manage.py test
  ```
- [ ] Fix any issues that arise from the restructuring

## Execution Strategy
1. Create a new branch for restructuring
2. Make incremental changes, committing after each logical step
3. Run tests frequently to catch issues early
4. Merge the restructuring branch once all tests pass

## Timeline
- Phase 1: 1-2 days
- Phase 2: 2-3 days
- Phase 3: 1 day
- Phase 4: 0.5 day
- Phase 5: 1 day
- Phase 6: 1-2 days
- Phase 7: 1-2 days

Total estimated time: 7-12 days

## Notes
- Before starting, create a complete backup of the project
- Consider using a task tracking system to manage the restructuring process
- Document any deviations from the plan and the reasons for them