# Puppetserver docker file
FROM registry.redhat.io/rhel7:latest

LABEL maintainer="Thomas Meeus <thomas.meeus@cegeka.com>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building Puppet Server images" \
      io.k8s.display-name="Openshift-puppetserver-image-builder" \
      io.openshift.expose-services="8140:https" \
      io.openshift.tags="openshift,docker,puppet,puppetserver,image,builder"


## Install Puppetserver & create Puppet code directory

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet \
    && yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/ \
    && yum -y install puppetserver mysql-devel ruby-devel openssl openssl-devel \
    && yum clean all -y \
    && touch /var/log/puppetlabs/puppetserver/masterhttp.log \
    && mkdir /usr/local/scripts \
    && mkdir /config \
    && mkdir -p /etc/cegeka/ssl/ca/

## Copy all required config files
COPY ./config/puppetserver.sh /usr/local/bin/start-puppet-server
COPY ./config/ca.cfg /etc/puppetlabs/puppetserver/services.d/ca.cfg
COPY ./config/webserver.conf /etc/puppetlabs/puppetserver/conf.d/webserver.conf
COPY ./config/check_registration.rb /usr/local/scripts
COPY ./config/openssl_ca.cnf /config

## Set correct permissions
RUN chmod +x /usr/local/bin/start-puppet-server \
    && chgrp -R 0 /opt/puppetlabs \
    && chgrp -R 0 /etc/puppetlabs \
    && chmod -R 771 /etc/puppetlabs/puppet/ssl \
    && mkdir /etc/puppetlabs/puppet/ssl/ca \
    && chgrp -R 0 /var/log/puppetlabs \
    && chmod 750 /var/log/puppetlabs/puppetserver \
    && chmod -R g=u /etc/puppetlabs \
    && chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log \
    && touch /tmp/.rnd \
    && chgrp -R 0 /tmp/.rnd \
    && chmod 777 /tmp/.rnd \
    && chgrp -R 0 /etc/cegeka/ssl/ca/ \
    && chmod 777 /etc/cegeka/ssl/ca/


#SSL config requirements
RUN echo "cacert = /certs/ca_crt.pem" >> /etc/puppetlabs/puppet/puppet.conf \
    && echo "autosign = /usr/local/scripts/check_registration.rb" >> /etc/puppetlabs/puppet/puppet.conf \
    && chown puppet:puppet /usr/local/scripts/check_registration.rb \
    && echo 0 >  /etc/puppetlabs/puppet/ssl/ca/serial \
    && touch /etc/puppetlabs/puppet/ssl/ca/inventory.txt \
    && echo 1000 > /etc/puppetlabs/puppet/ssl/ca/crlnumber \
    && echo > /etc/puppetlabs/puppet/ssl/ca/index.txt


## Copy over /etc/puppetlabs/code/ for the next builds
#ONBUILD COPY /tmp/src/ /etc/puppetlabs/code/



RUN echo '-----BEGIN RSA PRIVATE KEY-----' > /etc/cegeka/ssl/ca/ca_key.pem \
    && echo $CAKEY | tr ' ' '\n' >> /etc/cegeka/ssl/ca/ca_key.pem \
    && echo '-----END RSA PRIVATE KEY-----' >> /etc/cegeka/ssl/ca/ca_key.pem \
    && openssl ca -config /config/openssl_ca.cnf -gencrl -out /etc/puppetlabs/puppet/ssl/ca/ca_crl.pem

RUN echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${HOME}:/sbin/nologin" >> /etc/passwd
RUN chmod g=u /etc/passwd
USER 1001

EXPOSE 8140

CMD ["/usr/local/bin/start-puppet-server"]
