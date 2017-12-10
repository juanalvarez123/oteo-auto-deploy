#!/bin/bash

# Author:	Juan Sebastian Alvarez Eraso
# Date:		16/09/2017
# Version:	1.0

. variables.sh

function calculateTime {

	initTimeSeconds=$1
	initTimeDate=$2
	finalTimeSeconds=$3
	finalTimeDate=$4

	echo
	echo "Start: " $initTimeDate
	echo "Finish: " $finalTimeDate

	totalSeconds=`expr $finalTimeSeconds - $initTimeSeconds`
	minutes=$(($totalSeconds / 60))
	seconds=$(($totalSeconds - $minutes * 60))

	if [ "${#minutes}" == 1 ]; then
		minutes="0"$minutes;
	fi
	if [ "${#seconds}" == 1 ]; then
		seconds="0"$seconds;
	fi

	echo "Total: " $minutes:$seconds
	}

function stop {

	app=$1
	shift

	if [ -z "$app" ]; then
		docker rm -f $DATABASE_CONTAINER_NAME
		docker rm -f $API_REST_CONTAINER_NAME
	else
		case $app in
			database) docker rm -f $DATABASE_CONTAINER_NAME ;;
			rest-api) docker rm -f $API_REST_CONTAINER_NAME ;;
			*) echo 'Invalid option, use: . oteo.sh help' ;;
		esac
	fi

	cd $OTEO_AUTO_DEPLOY
	}

# Waits until specified container start
function wait_container {

	container=$1
	shift

	case $container in

		database)
			printf "Waiting for database container "
			while ! curl http://localhost:15432/ -s
			do
				printf "."
				sleep 1
			done
			;;

	esac

	echo
	}

function start_database_application {

	docker run -d --name=$DATABASE_CONTAINER_NAME \
	-e POSTGRES_DB=$POSTGRES_DB \
	-e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
	-p 15432:5432 \
	$DATABASE_IMAGE_NAME:$DATABASE_IMAGE_TAG

	#wait_container database
	sleep 10

	# Execute liquibase for develop environment
	cd $OTEO_DATABASE_LIQUIBASE
	mvn liquibase:update -P develop
	}

function start_oteo_rest_api_application {

	cd $OTEO_PARENT
	mvn -T 2C install -Dmaven.test.skip=true -Dcobertura.skip
	rm docker/*.jar
	cp oteo-rest-api/target/*.jar docker/

	cd $OTEO_PARENT/docker/
	docker build -t $API_REST_IMAGE_NAME:$API_REST_IMAGE_TAG .

	docker run -d --link=$DATABASE_CONTAINER_NAME --name=$API_REST_CONTAINER_NAME \
	-e SPRING_DATASOURCE_URL=$SPRING_DATASOURCE_URL \
	-e SPRING_DATASOURCE_USERNAME=$SPRING_DATASOURCE_USERNAME \
	-e SPRING_DATASOURCE_PASSWORD=$SPRING_DATASOURCE_PASSWORD \
	-e SPRING_DATASOURCE_INITIAL_SIZE=$SPRING_DATASOURCE_INITIAL_SIZE \
	-e SPRING_DATASOURCE_MAX_ACTIVE=$SPRING_DATASOURCE_MAX_ACTIVE \
	-e SPRING_DATASOURCE_MIN_IDLE=$SPRING_DATASOURCE_MIN_IDLE \
	-e SPRING_DATASOURCE_MAX_IDLE=$SPRING_DATASOURCE_MAX_IDLE \
	-e SPRING_DATASOURCE_MAX_WAIT_MILLIS=$SPRING_DATASOURCE_MAX_WAIT_MILLIS \
	-p 18080:8080 \
	-p 18081:8081 \
	$API_REST_IMAGE_NAME:$API_REST_IMAGE_TAG
	}

function start {

	app=$1
	shift

	if [ -z "$app" ]; then
		start_database_application
		start_oteo_rest_api_application
	else
		case $app in
			database) start_database_application ;;
			rest-api) start_oteo_rest_api_application ;;
			*) echo 'Invalid option, use: . oteo.sh help' ;;
		esac
	fi

	cd $OTEO_AUTO_DEPLOY
	}

function execute_liquibase {

	environment=$1
	shift

	cd $OTEO_DATABASE_LIQUIBASE

	case $environment in
		develop) mvn liquibase:update -P develop ;;
		stage) mvn liquibase:update -P stage ;;
		production) mvn liquibase:update -P production ;;
		*) echo 'Invalid option, use: . oteo.sh help' ;;
	esac

	cd $OTEO_AUTO_DEPLOY
	}

function deploy {

	environment=$1
	shift

	case $environment in

		stage)
			cd $OTEO_PARENT
			git checkout stage
			git pull origin stage
			git pull origin develop
			git push origin stage
			git checkout develop

			cd $OTEO_WEB
			git checkout stage
			git pull origin stage
			git pull origin develop
			git push origin stage
			git checkout develop
			;;

		production)
			cd $OTEO_PARENT
			git checkout production
			git pull origin production
			git pull origin develop
			git push origin production
			git checkout develop

			cd $OTEO_WEB
			git checkout production
			git pull origin production
			git pull origin develop
			git push origin production
			git checkout develop
			;;

		*)
			echo 'Invalid option, use: . oteo.sh help'
			;;

	esac

	cd $OTEO_AUTO_DEPLOY
	}

# Init function
function oteo {

	initTimeSeconds=$(date -d now "+%s")
	initTimeDate=$(date)

	opc1=$1
	opc2=$2
	shift

	case $opc1 in

		start)
			stop $opc2
			start $opc2
			;;

		stop)
			stop $opc2
			;;

		liquibase)
			execute_liquibase $opc2
			;;

		deploy)
			deploy $opc2
			execute_liquibase $opc2
			;;

		*)
			echo 'Invalid option, use: . oteo.sh help'
			;;

	esac

	finalTimeSeconds=$(date -d now "+%s")
	finalTimeDate=$(date)
	calculateTime $initTimeSeconds "$initTimeDate" $finalTimeSeconds "$finalTimeDate"
	}

oteo $@