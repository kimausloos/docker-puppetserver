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


COPY ./config/uid_entrypoint /


## Install Puppetserver & create Puppet code directory

ENV USER_NAME=puppet \
    HOME_DIR=/var/lib/puppet \
    USER_UID=200

RUN useradd -l -u ${USER_UID} -r -g 0 -m -d ${HOME_DIR} -s /sbin/no-login -c "${USER_NAME} application user" ${USER_NAME} \
            && chmod -R g+rw ${HOME_DIR} /etc/passwd \
            && chmod ug+x /uid_entrypoint

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet \
    && yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/ \
    && yum -y install puppetserver mysql-devel ruby-devel \
    && yum clean all -y \
    && find ${HOME_DIR} -type d -exec chmod g+x {} + \
    && touch /var/log/puppetlabs/puppetserver/masterhttp.log \
    && mkdir /usr/local/scripts \
    && mkdir /config



VOLUME /etc/cegeka/ssl/ca/


## Copy all required config files
COPY ./config/puppetserver.sh /usr/local/bin/start-puppet-server
COPY ./config/ca.cfg /etc/puppetlabs/puppetserver/services.d/ca.cfg
COPY ./config/webserver.conf /etc/puppetlabs/puppetserver/conf.d/webserver.conf
COPY ./config/check_registration.rb /usr/local/scripts
COPY ./config/openssl_ca.cnf /config

## Set correct permissions
RUN chmod +x /usr/local/bin/start-puppet-server \
#    && chgrp -R 0 /opt/puppetlabs \
#    && chgrp -R 0 /etc/puppetlabs \
    && chmod -R 771 /etc/puppetlabs/puppet/ssl \
    && mkdir /etc/puppetlabs/puppet/ssl/ca \
#    && chgrp -R 0 /var/log/puppetlabs \
    && chmod 750 /var/log/puppetlabs/puppetserver \
#    && chmod -R g=u /etc/puppetlabs \
    && chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log
#    && chgrp -R 0 /etc/cegeka/ssl/ca/ \
#    && chmod 777 /etc/cegeka/ssl/ca/ \
#    && mkdir -p /var/run/puppetlabs/puppetserver \
#    && chgrp -R 0 /var/run/puppetlabs/puppetserver


#SSL config requirements
RUN echo "cacert = /certs/ca_crt.pem" >> /etc/puppetlabs/puppet/puppet.conf \
    && echo "autosign = /usr/local/scripts/check_registration.rb" >> /etc/puppetlabs/puppet/puppet.conf \
    && chown puppet:puppet /usr/local/scripts/check_registration.rb \
    && echo 0 >  /etc/puppetlabs/puppet/ssl/ca/serial \
    && touch /etc/puppetlabs/puppet/ssl/ca/inventory.txt \
    && echo 1000 > /etc/puppetlabs/puppet/ssl/ca/crlnumber \
    && echo > /etc/puppetlabs/puppet/ssl/ca/index.txt

RUN find /etc/puppetlabs -type d -exec chmod g+x {} +
RUN sed "s@${USER_NAME}:x:${USER_UID}:@${USER_NAME}:x:\${USER_ID}:@g" /etc/passwd > /etc/passwd.template

## Copy over /etc/puppetlabs/code/ for the next builds
#ONBUILD COPY /tmp/src/ /etc/puppetlabs/code/
USER 200


EXPOSE 8140
ENTRYPOINT [ "/uid_entrypoint" ]

CMD ["/sbin/init"]
