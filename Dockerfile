FROM docker.io/debian:stable-slim
RUN apt install curl -y && \
    cd /tmp/ && \
    wget https://github.com/hetznercloud/cli/releases/download/v1.20.0/hcloud-linux-amd64.tar.gz && \
    tar -xvf hcloud-linux-amd64.tar.gz &&\ 
    mv hcloud /usr/local/bin && \
    rm -f hcloud-linux-amd64.tar.gz && \
    wget https://storage.googleapis.com/kubernetes-release/release/v1.18.3/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    rm -rf /tmp/*

COPY hcloud-okd4-firewall-controller.sh .
CMD ["hcloud-okd4-firewall-controller.sh"]