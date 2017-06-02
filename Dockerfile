FROM openshift/python:3.5

MAINTAINER Koray Seremet <koray@redhat.com>

LABEL name="ecr-token-refresher" \
      architecture="x86_64" \
      io.k8s.display-name="ECR Token Refresher" \
      io.k8s.description="Amazon ECR registry token refresher" \
      io.openshift.tags="openshift,aws,ecr"

ENV LD_LIBRARY_PATH=/opt/rh/rh-python35/root/usr/lib64/
RUN export LD_LIBRARY_PATH=/opt/rh/rh-python35/root/usr/lib64:$LD_LIBRARY_PATH && \ 
    pip install --upgrade pip awscli boto3
COPY scripts/ecr-token-refresher.sh /usr/local/bin
CMD /usr/local/bin/ecr-token-refresher.sh
