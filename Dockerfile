#
# builder stage
#
FROM node:16 AS builder
WORKDIR /usr/app
COPY . .
RUN chmod +x ./dev.sh
RUN ./dev.sh build 
# strip all the dev dependencies needed by build in the builder container
# keep the production image as small as possible
RUN npm ci --only=production

#
# production image stage
#
FROM node:16-alpine
WORKDIR /usr/app
COPY --from=builder /usr/app ./
EXPOSE 3000
CMD [ "node", "bin/www" ]