FROM openshift/python:3.5

MAINTAINER Koray Seremet <koray@redhat.com>

LABEL name="ecr-token-refresher" \
      architecture="x86_64" \
      io.k8s.display-name="ECR Token Refresher" \
      io.k8s.description="Amazon ECR registry token refresher" \
      io.openshift.tags="openshift,aws,ecr"

USER root
ENV LD_LIBRARY_PATH=/opt/rh/rh-python35/root/usr/lib64/
RUN export LD_LIBRARY_PATH=/opt/rh/rh-python35/root/usr/lib64:$LD_LIBRARY_PATH && \ 
    pip install --upgrade pip awscli boto3 && \
    yum install --setopt=tsflags=nodocs --enablerepo=rhel-7-server-ose-3.5-rpms atomic-openshift-clients
COPY scripts/ecr-token-refresher.sh /opt/app-root/bin

RUN chmod 755 /opt/app-root/bin/ecr-token-refresher.sh
CMD /opt/app-root/bin/ecr-token-refresher.sh
