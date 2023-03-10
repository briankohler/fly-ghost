FROM litestream/litestream:latest AS builder

FROM ghost:5.27.0-alpine
WORKDIR /var/lib/ghost
RUN npm install ghost-storage-base
COPY --from=builder /usr/local/bin/litestream /usr/local/bin/litestream
ADD litestream.yml /etc/litestream.yml
ADD run.sh /usr/local/bin/run.sh

USER node
CMD /usr/local/bin/run.sh
