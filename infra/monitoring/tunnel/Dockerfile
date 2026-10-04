# autossh client for the phase-3 reverse SSH tunnel to the Azure production VM.
# Built on the monitoring VM while a captive-portal session is up:
#   docker compose --profile tunnel build
#
# The SSH private key is never baked in — it is bind-mounted read-only from
# ./secrets at runtime (see docker-compose.yml) and is git-ignored.
FROM alpine:3.22

RUN apk add --no-cache autossh openssh-client

ENTRYPOINT ["autossh"]
