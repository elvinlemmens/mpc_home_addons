# MPC Optimizer + Dashboard - Home Assistant add-on.
# Bakes the (heavy) dependencies + build tools + git; the application code is
# pulled from the private GitHub repo at container start by run.sh. Changing
# code = bump GIT_REF + restart; changing dependencies = edit this list + rebuild.
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc g++ git \
    && rm -rf /var/lib/apt/lists/*

# Keep this list in sync with the private repo's requirements.txt (it cannot be
# COPYed in because the code is pulled at start, not at build).
RUN pip install --no-cache-dir \
        influxdb-client pandas numpy scipy scikit-learn pvlib requests \
        paho-mqtt linopy highspy pyarrow matplotlib fastapi uvicorn pyyaml pypdf

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["bash", "/run.sh"]
