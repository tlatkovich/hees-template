# base image for running the app, will be used in the final image below
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80 443 2222

# image for building the app
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

ARG PAT
# copy only .sln and .csproj files and restore as distinct layers,
# this avoid rebuilding layers when source code changes
COPY ["./Api.DomainName/*.csproj", "./Api.DomainName/"]
COPY ["./Api.DomainName.Data/*.csproj", "./Api.DomainName.Data/"]
COPY ["./DevOps.Api.DomainName.sln", "."]
COPY ["./nuget.config","."]

RUN dotnet nuget update source Hees-One --username "Hees-One" --password "$PAT" --valid-authentication-types basic --store-password-in-clear-text
RUN dotnet restore --ignore-failed-sources

# copy source code and build the app
# we don't need to copy the ARM template
COPY ["Api.DomainName/", "Api.DomainName/"]
COPY ["Api.DomainName.Data/", "Api.DomainName.Data/"]

WORKDIR "/src/Api.DomainName"
RUN dotnet build -c Release --no-restore

FROM build AS publish
RUN dotnet publish -c Release --no-build -o /app

# RUN apt update \
#       && apt install -y --no-install-recommends openssh-server \
#       && mkdir -p /run/sshd \
#       && echo "root:Docker!" | chpasswd

# RUN mkdir -p /var/log/supervisor
# COPY sshd_config /etc/ssh/sshd_config

# final image for running the app
FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Api.DomainName.dll"]
#ENTRYPOINT [ "/bin/bash", "-c", "/usr/sbin/sshd && dotnet Api.Validation.dll" ]