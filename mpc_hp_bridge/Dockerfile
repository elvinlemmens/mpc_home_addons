# MPC HP Bridge - Home Assistant add-on.
# The image bakes only the dependencies + git; the application code is pulled
# from the private GitHub repo at container start by run.sh (pull-at-start).
# Changing code = bump the GIT_REF option and restart; changing dependencies =
# edit this list + rebuild.
FROM python:3.11-alpine

RUN apk add --no-cache git

RUN pip install --no-cache-dir paho-mqtt influxdb-client pyyaml

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/bin/sh", "/run.sh"]
