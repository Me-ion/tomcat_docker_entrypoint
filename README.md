# tomcat_docker_entrypoint
Entry point script to trap docker signals. Could be easily modified to handle other applications and other log files.
Allows both redirecting application logs to a log file which could be mounted for external log agregation services, e.g. Splunk,
aw well as redirecting the logs to the container's stdout -> `docker/kubectl logs ....`

## To use the script:
- Add the script to the same directory as the Dockerfile
- In the Dockerfile, add following steps:
```bash
COPY ./docker-entrypoint.sh /

# tini runs as PID 1, acting like a simple init system. It launches a single process and then proxies
# all received signals to a session rooted at that child process. See https://github.com/krallin/tini
ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]
```

### Additional:
Could also add more logic into the `stop()` function to call the application's shutdown endpoint (if implemented) to return a non 200 code, e.g. 500 and wait for a few seconds so that the load balancer drains the connections and does not send new connections to the continer/pod
