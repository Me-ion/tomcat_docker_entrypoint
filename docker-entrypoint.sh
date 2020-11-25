#!/usr/bin/env bash

#set -x

trap stop SIGTERM SIGINT SIGQUIT SIGHUP ERR

declare context=$(basename $(find "$CATALINA_HOME/webapps/" -mindepth 1 -maxdepth 1 ! -name ROOT -type d))
declare warnLogPrefix="WARN  [docker-entrypoint] <$context>"
declare errorLogPrefix="ERROR  [docker-entrypoint] <$context>"
declare debugEnabled="${ENABLE_DEBUG:-false}"
declare -i waitBeforeJavaThreadDump="${WAIT_BEFORE_THREAD_DUMP:-120}"
declare triggerThreadDumpBeforeStop="${TRIGGER_THREAD_DUMP_BEFORE_STOP:-false}"

start(){
	local catalinaPid

	# hacky way to "initialize" the output file
	echo " " >> "$CATALINA_OUT"
	tail --pid $$ -n 0 -F "${CATALINA_OUT}" &

	echo "$(date +'%F %T,%3N') ${warnLogPrefix} Starting tomcat" >> "$CATALINA_OUT"

	touch "${CATALINA_PID}"
	catalina.sh run >> ${CATALINA_OUT} 2>&1 &
	catalinaPid=$!
	echo "$catalinaPid" > "${CATALINA_PID}"

	wait "$catalinaPid"
}

stop(){
	local catalinaPid

	catalinaPid=$(cat "${CATALINA_PID}")

	if "$triggerThreadDumpBeforeStop"; then
		echo "$(date +'%F %T,%3N') ${warnLogPrefix} Triggering pre-stop thread dump" >> "$CATALINA_OUT"
		kill -3 "$catalinaPid"
	fi

	echo "$(date +'%F %T,%3N') ${warnLogPrefix} Initiating tomcat stop" >> "$CATALINA_OUT"

	catalina.sh stop "${waitBeforeJavaThreadDump}" >> "$CATALINA_OUT"
	wait "$catalinaPid"

  echo "$(date +'%F %T,%3N') ${warnLogPrefix} Completed tomcat stop" >> "$CATALINA_OUT"

	# give a sec for the tail to catch up with all the logs
	sleep 1
	exit
}

if [[ "$-" == *x* ]]; then
	debugEnabled='true'
	sed -i '/env bash/a set -x' "${CATALINA_HOME}/bin/catalina.sh"
fi

start
