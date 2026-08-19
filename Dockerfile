# syntax=docker.io/docker/dockerfile:1
FROM alpine:latest AS build

WORKDIR /build

RUN apk update \
    && apk upgrade \
    && apk add ca-certificates \
    aspnetcore10-runtime \
    dotnet10-sdk \
    git \
    curl \
    libgcc \
    libssl3 \
    zlib \
    icu-libs \
    icu-data-full \
    tzdata 

RUN git clone --depth 1 https://github.com/TechnitiumSoftware/TechnitiumLibrary.git TechnitiumLibrary
RUN git clone --depth 1 https://github.com/TechnitiumSoftware/DnsServer.git DnsServer

RUN dotnet build TechnitiumLibrary/TechnitiumLibrary.ByteTree/TechnitiumLibrary.ByteTree.csproj -c Release
RUN dotnet build TechnitiumLibrary/TechnitiumLibrary.Net/TechnitiumLibrary.Net.csproj -c Release
RUN dotnet build TechnitiumLibrary/TechnitiumLibrary.Security.OTP/TechnitiumLibrary.Security.OTP.csproj -c Release

RUN dotnet publish DnsServer/DnsServerApp/DnsServerApp.csproj -c Release

FROM alpine:latest

RUN apk add -U --no-cache aspnetcore10-runtime dotnet10-sdk libmsquic doggo

RUN addgroup -S dns-server \
    && adduser -S -G dns-server dns-server

WORKDIR /opt/technitium/dns

COPY --link /build/DnsServer/DnsServerApp/bin/Release/publish /opt/technitium/dns

ENTRYPOINT ["/usr/bin/dotnet", "/opt/technitium/dns/DnsServerApp.dll"]
CMD ["/etc/dns"]

EXPOSE \
   53/udp 53/tcp \
   853/udp 853/tcp \
   443/udp 443/tcp \
   80/tcp 8053/tcp \
   5380/tcp 5380/tcp \
   67/udp

LABEL org.opencontainers.image.title="ASMGH-67-DNS"
LABEL org.opencontainers.image.source="https://github.com/prothesmos/dns-67"

