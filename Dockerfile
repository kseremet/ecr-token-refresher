FROM openshift/python:3.5

MAINTAINER Koray Seremet <koray@redhat.com>

LABEL com.redhat.component="skopeo" \
      name="ecr-token-refresher" \
      architecture="x86_64" \
      io.k8s.display-name="ECR Token Refresher" \
      io.k8s.description="Amazon ECR registry token refresher" \
      io.openshift.tags="openshift,aws"

USER root

RUN pip install --upgrade awscli boto3
COPY scripts/ecr-token-refresher.sh /usr/local/bin
WORKDIR /tmp

USER 1001

CMD /usr/local/bin/ecr-token-refresher.sh
