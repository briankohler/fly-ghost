FROM litestream/litestream:latest AS builder

FROM ghost:5.27.0-alpine
WORKDIR /var/lib/ghost
RUN npm install ghost-storage-base ghost-storage-adapter-s3 \
     && mkdir -p ./content/adapters/storage \
     && cp -r ./node_modules/ghost-storage-adapter-s3 ./content/adapters/storage/s3
COPY --from=builder /usr/local/bin/litestream /usr/local/bin/litestream
ADD litestream.yml /etc/litestream.yml
ADD run.sh /usr/local/bin/run.sh

USER node
CMD /usr/local/bin/run.sh
