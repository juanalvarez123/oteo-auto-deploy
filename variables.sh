#!/bin/bash

export HOME_GIT=/c/Users/j.alvarez/git

# Git repositories
export OTEO_PARENT=$HOME_GIT/oteo-parent
export OTEO_WEB=$HOME_GIT/oteo-web
export OTEO_AUTO_DEPLOY=$HOME_GIT/oteo-auto-deploy
export OTEO_DATABASE_LIQUIBASE=$HOME_GIT/oteo-database-liquibase

# Containers
export DATABASE_CONTAINER_NAME="oteo-database-container"
export API_REST_CONTAINER_NAME="oteo-api-rest-container"
export WEB_CONTAINER_NAME="oteo-web-container"

# Images
export DATABASE_IMAGE_NAME="postgres"
export API_REST_IMAGE_NAME="oteo-api-rest-image"
export WEB_IMAGE_NAME="oteo-web-image"

# Tags
export DATABASE_IMAGE_TAG="9.6"
export API_REST_IMAGE_TAG="0.0.1"
export WEB_IMAGE_TAG="0.0.1"

# oteo-database environment variables
export POSTGRES_DB="oteo-database"
export POSTGRES_PASSWORD="postgres"

# oteo-parent environment variables
export SPRING_DATASOURCE_URL="jdbc:postgresql://oteo-database-container:5432/oteo-database"
export SPRING_DATASOURCE_USERNAME="postgres"
export SPRING_DATASOURCE_PASSWORD="postgres"
export SPRING_DATASOURCE_INITIAL_SIZE="25"
export SPRING_DATASOURCE_MAX_WAIT_MILLIS="1000"
export SPRING_DATASOURCE_MAX_ACTIVE="200"
export SPRING_DATASOURCE_MIN_INDLE="25"
export SPRING_DATASOURCE_MAX_IDLE="50"

# oteo-web environment variables
export REACT_APP_URL_OTEO_REST_API="http://localhost:18080/oteo-rest-api"
