# #####################################################
# onemarcfifty/kali-linux
# #####################################################
#
# This Dockerfile will build a Kali Linux Docker
# image with a graphical environment
#
# It loads the following variables from the env file:
#
#  - Ports to use for  SSH, and RDP
#    (RDP_PORT, SSH_PORT)
#  - Desktop environment(DESKTOP_ENVIRONMENT)
#  - Remote access software (REMOTE_ACCESS)
#  - Kali packages to install (KALI_PACKAGE)
#  - Network configuration  (NETWORK)
#  - Build platform (BUILD_PLATFORM)
#  - Local Docker image name (DockerIMG)
#  - Docker container name (CONTAINER)
#  - Host directory to mount as volume
#  - Container directory for volume mount (HOSTDIR)
#  - Container username (USERNAME)
#  - Container user password
#
# The start script is called /startkali.sh
# and it will be built dynamically by the Docker build
# process
#
# #####################################################

ARG KALI_IMAGE_BASE_TAG

FROM gitlab.fi.muni.cz:5050/cybersec/infra/images/kali/kali-rolling-base:${KALI_IMAGE_BASE_TAG:-20240811}

ENV DEBIAN_FRONTEND=noninteractive


# #####################################################
# the desktop environment to use
# if it is null then it will default to xfce
# valid choices are
# e17, gnome, i3, i3-gaps, kde, live, lxde, mate, xfce
#
# However, only xfce works with xrdp, thus it is hard set to xfce
# #####################################################

ENV DESKTOP_ENVIRONMENT=xfce
ENV DESKTOP_PKG=kali-desktop-${DESKTOP_ENVIRONMENT}

# #####################################################
# the remote client to use
# if it is null then it will default to xrdp
# valid choices are xrdp
# #####################################################

ARG RDP_PORT
ENV REMOTE_ACCESS=xrdp

# #####################################################
# the kali packages to install
# if it is null then it will default to "default"
# valid choices are arm, core, default, everything,
# firmware, headless, labs, large, nethunter
# #####################################################

ARG KALI_PACKAGE
ENV KALI_PACKAGE=${KALI_PACKAGE:-default}
ENV KALI_PKG=kali-linux-${KALI_PACKAGE}

RUN apt update -q --fix-missing && \
  apt -y install --no-install-recommends ca-certificates && \
  # Fix a problem where downloading of all apt packages would
  # fail with "Unable to connect to..."
  # src: https://unix.stackexchange.com/a/429734
  sed -i 's|http://|https://|g' /etc/apt/sources.list && \
  apt update -q --fix-missing && \
  apt upgrade -y && \
  apt -y install --no-install-recommends sudo wget curl dbus-x11 xinit openssh-server ${DESKTOP_PKG} ${KALI_PKG} xorg xorgxrdp xrdp locales && \
  sed -i s/^#\ en_US.UTF-8\ UTF-8/en_US.UTF-8\ UTF-8/ /etc/locale.gen && \
  locale-gen && \
  # Configure xrdp
  # Currently, xrdp only works with the xfce desktop
  echo "rm -rf /var/run/xrdp >/dev/null 2>&1" >> /startkali.sh ; \
  echo "/etc/init.d/xrdp start" >> /startkali.sh ; \
  sed -i s/^port=3389/port=${RDP_PORT}/ /etc/xrdp/xrdp.ini ; \
  adduser xrdp ssl-cert ; \
  echo xfce4-session > /home/${UNAME}/.xsession ; \
  chmod +x /home/${UNAME}/.xsession ;

#############################################################
# PA211 extenisons of pacakges required for the course
#############################################################

RUN apt -y install --no-install-recommends \
  zaproxy \
  wordlists \
  dirb \
  gobuster \
  feroxbuster \
  ffuf \
  wfuzz \
  whatweb \
  sqlmap \
  wpscan \
  nuclei \
  burpsuite \
  dirbuster \
  bind9-host \
  sqlmap \
  hydra \
  vim \
  nano \
  wget \
  nmap \
  less \
  net-tools \
  inetutils-ping \
  dnsutils \
  smbmap \
  smbclient \
  zip \
  git \
  jq \
  cifs-utils \
  telnet

ARG UNAME
ARG UPASS
ARG SSH_PORT

RUN \
  # disable power manager plugin xfce
  rm /etc/xdg/autostart/xfce4-power-manager.desktop >/dev/null 2>&1 && \
  if [ -e /etc/xdg/xfce4/panel/default.xml ] ; then \
    sed -i s/power/fail/ /etc/xdg/xfce4/panel/default.xml ; \
  fi && \
  \
  # create the non-root kali user
  useradd -m -s /bin/bash -G sudo ${UNAME} && \
  echo "${UNAME}:${UPASS}" | chpasswd && \
  \
  # create the start bash shell file
  echo "#!/bin/bash" > /startkali.sh && \
  echo "/etc/init.d/ssh start" >> /startkali.sh && \
  echo "/bin/bash" >> /startkali.sh && \
  chmod 755 /startkali.sh && \
  \
  # change the ssh port in /etc/ssh/sshd_config
  # When you use the bridge network, then you would
  # not have to do that. You could rather add a port
  # mapping argument such as -p 2022:22 to the
  # Docker create command. But we might as well
  # use the host network and port 22 might be taken
  # on the Docker host. Hence we change it
  # here inside the container
  echo "Port $SSH_PORT" >>/etc/ssh/sshd_config

# ###########################################################
# expose the right ports and set the entrypoint
# ###########################################################

EXPOSE ${SSH_PORT} ${RDP_PORT}
WORKDIR "/root"
ENTRYPOINT ["/bin/bash"]
CMD ["/startkali.sh"]
