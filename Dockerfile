FROM alpine:latest

RUN apk add --update --no-cache bash curl yq

COPY d2c.sh /usr/local/bin

ENTRYPOINT ["/usr/local/bin/d2c.sh"]
