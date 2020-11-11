FROM docker.io/alpine:3.12
RUN      && \
    tar -xvf hcloud-linux-amd64.tar.gz && \
    mv hcloud /usr/local/bin && \
    rm -f hcloud-linux-amd64.tar.gz && \
    wget https://github.com/openshift/okd/releases/download/4.5.0-0.okd-2020-10-15-235428/openshift-client-linux-4.5.0-0.okd-2020-10-15-235428.tar.gz -O openshift-client-linux.tar.gz && \
    tar -xvf openshift-client-linux.tar.gz