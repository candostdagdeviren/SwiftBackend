FROM ibmcom/swift-ubuntu:latest
MAINTAINER Candost Dagdeviren <candostdagdeviren@gmail.com>
ADD . /app
WORKDIR /app
EXPOSE 8090
USER root
RUN swift build
CMD [".build/debug/SwiftBackendApp"]
