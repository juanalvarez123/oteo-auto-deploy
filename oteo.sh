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

function stop_oteo {

	docker rm -f $DATABASE_CONTAINER_NAME
	docker rm -f $API_REST_CONTAINER_NAME
	docker rm -f $WEB_CONTAINER_NAME
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

function start_oteo {

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

	cd $OTEO_PARENT
	mvn clean install -Dmaven.test.skip=true
	rm docker/*.jar
	cp oteo-rest-api/target/*.jar docker/

	cd $OTEO_PARENT/docker/
	docker build -t $API_REST_IMAGE_NAME:$API_REST_IMAGE_TAG .

	docker run -d --link=$DATABASE_CONTAINER_NAME --name=$API_REST_CONTAINER_NAME \
	-e SPRING_DATASOURCE_URL=$SPRING_DATASOURCE_URL \
	-e SPRING_DATASOURCE_USERNAME=$SPRING_DATASOURCE_USERNAME \
	-e SPRING_DATASOURCE_PASSWORD=$SPRING_DATASOURCE_PASSWORD \
	-e SPRING_DATASOURCE_INITIAL_SIZE=$SPRING_DATASOURCE_INITIAL_SIZE \
	-e SPRING_DATASOURCE_MAX_WAIT_MILLIS=$SPRING_DATASOURCE_MAX_WAIT_MILLIS \
	-e SPRING_DATASOURCE_MAX_ACTIVE=$SPRING_DATASOURCE_MAX_ACTIVE \
	-e SPRING_DATASOURCE_MIN_INDLE=$SPRING_DATASOURCE_MIN_INDLE \
	-e SPRING_DATASOURCE_MAX_IDLE=$SPRING_DATASOURCE_MAX_IDLE \
	-p 18080:8080 \
	-p 18081:8081 \
	$API_REST_IMAGE_NAME:$API_REST_IMAGE_TAG

	#cd $OTEO_WEB/docker
	#rm -rf oteo-web/
	#mkdir oteo-web
	#cd $OTEO_WEB
	#cp index.html docker/oteo-web/
	#cp -r app/ docker/oteo-web/app/
    #
	#cd $OTEO_WEB/docker
	#docker build -t $WEB_IMAGE_NAME:$WEB_IMAGE_TAG .
    #
	#docker run -d --link=$API_REST_CONTAINER_NAME --name=$WEB_CONTAINER_NAME \
	#-e "REACT_APP_URL_OTEO_REST_API=$REACT_APP_URL_OTEO_REST_API" \
	#-p 18082:8080 \
	#$WEB_IMAGE_NAME:$WEB_IMAGE_TAG
    #
	#cd $OTEO_WEB/docker
	#rm -rf oteo-web/
	#mkdir oteo-web

	cd $OTEO_AUTO_DEPLOY
	}

function execute_liquibase {

	environment=$1
	shift

	cd $OTEO_DATABASE_LIQUIBASE

	case $environment in

		stage)
			mvn liquibase:update -P stage
			;;

		production)
			mvn liquibase:update -P production
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

	opc=$1
	environment=$2
	shift

	case $opc in

		start)
			stop_oteo
			start_oteo
			;;

		stop)
			stop_oteo
			;;

		liquibase)
			execute_liquibase $environment
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