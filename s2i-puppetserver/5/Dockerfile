# This image provides a base for running puppet code.

FROM registry.access.redhat.com/rhscl/s2i-base-rhel7:latest

MAINTAINER Computing <computing@cegeka.com>

EXPOSE 8140

ENV PUPPETSERVER_VERSION=5
VOLUME /etc/puppetlabs/code/environments

LABEL io.k8s.description="Platform for building and running puppet code on Puppetserver 5" \
      io.k8s.display-name="Puppetserver 5" \
      io.openshift.expose-services="8140:https" \
      io.openshift.tags="builder,puppertserver,puppetserver5" \
      io.openshift.s2i.assemble-input-files="/etc/puppetlabs/puppetserver/services.d;/etc/puppetlabs/puppetserver/conf.d" \
      io.openshift.s2i.destination="/etc/puppetlabs/puppetserver" \
      com.redhat.deployments-dir="/etc/puppetlabs/puppetserver" \
      maintainer="Computing <computing@cegeka.com>"

RUN INSTALL_PKGS="puppetserver" \
  && rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet \
  && yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/ \
  && yum -y install $INSTALL_PKGS \
  && yum clean all -y \
  && mkdir -p /opt/s2i/destination \
  && mv $STI_SCRIPTS_PATH/run $STI_SCRIPTS_PATH/run-base \
  && mv $STI_SCRIPTS_PATH/assemble $STI_SCRIPTS_PATH/assemble-base \

# Add s2i puppetserver customizations
ADD ./scripts/puppetserver.sh /usr/local/bin/start-puppet-server
ADD ./conf/ca.cfg /etc/puppetlabs/puppetserver/services.d/ca.cfg
ADD ./conf/webserver.conf /etc/puppetlabs/puppetserver/conf.d/webserver.conf

RUN FIX_PERMS="chmod +x /usr/local/bin/start-puppet-server && \
chgrp -R 0 /opt/puppetlabs/ && \
chgrp -R 0 /etc/puppetlabs && \
chmod -R 771 /etc/puppetlabs/puppet/ssl && \
chgrp -R 0 /var/log/puppetlabs && \
chmod 750 /var/log/puppetlabs/puppetserver && \
touch /var/log/puppetlabs/puppetserver/masterhttp.log && \
chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log"

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/* $STI_SCRIPTS_PATH/

CMD $STI_SCRIPTS_PATH/usage
