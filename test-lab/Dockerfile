# Throwaway "fake vulnbox" for testing adducksetup. NOT for real use.
# Has sshd + tcpdump + a deliberately vulnerable ping service so you can
# run the whole capture -> pull -> dashboard pipeline on one Pwnbox.
FROM ubuntu:22.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      openssh-server tcpdump iproute2 python3 curl rsync \
    && rm -rf /var/lib/apt/lists/*

# allow root ssh with password "root" (test lab only)
RUN mkdir -p /run/sshd \
    && echo 'root:root' | chpasswd \
    && sed -i 's/#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

COPY vuln_service.py /root/vuln_service.py
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 8080
CMD ["/entrypoint.sh"]
