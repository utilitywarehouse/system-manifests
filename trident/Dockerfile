FROM fedora

ENV TRIDENT_VERSION='25.06.0'

RUN \
  curl -L https://github.com/NetApp/trident/releases/download/v${TRIDENT_VERSION}/trident-installer-${TRIDENT_VERSION}.tar.gz -o trident-installer.tar.gz \
  && tar zxf trident-installer.tar.gz -C /usr/local/lib \
  && rm -f trident-installer.tar.gz \
  && ln -s /usr/local/lib/trident-installer/tridentctl /usr/local/bin/tridentctl

WORKDIR /opt/trident
