# escape=`
FROM mcr.microsoft.com/windows/nanoserver:1809 as builder
WORKDIR C:/Users/ContainerUser
ADD https://github.com/portainer/portainer/releases/download/1.20.1/portainer-1.20.1-windows-amd64.tar.gz portainer.tgz
# TODO verify the tgz sha256sum
RUN tar xf portainer.tgz

FROM mcr.microsoft.com/windows/nanoserver:1809
EXPOSE 9000
COPY --from=builder /Users/ContainerUser/portainer /app
# NB running as ContainerAdministrator is needed to access the docker named pipe.
USER ContainerAdministrator
RUN mkdir c:\data
VOLUME ["C:/data"]
WORKDIR /app
ENTRYPOINT ["/app/portainer.exe", "--no-auth", "--template-file", "templates.json"]
