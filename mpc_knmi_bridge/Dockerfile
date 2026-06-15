# MPC KNMI MSG-CPP Bridge - Home Assistant add-on.
# Bakes dependencies + git; the application code is pulled from the private
# GitHub repo at container start by run.sh. Changing code = bump GIT_REF +
# restart; changing dependencies = edit this list + rebuild.
FROM python:3.11-alpine

RUN apk add --no-cache git

RUN pip install --no-cache-dir requests pandas influxdb-client pyyaml

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/bin/sh", "/run.sh"]
